extends Node3D
class_name Weapon
## Shared hitscan weapon (Person 1, shared mechanics).
##
## One rifle. Hitscan raycast from a supplied aim origin along an aim direction,
## with a simple spread model (spread grows while moving and while firing),
## fire-rate limiting, a magazine and reload. The player and bots (Person 2) use
## this same weapon and the same rules — bots drive it through aim origin/dir,
## never by passing a target reference.
##
## Fairness boundary (AGENTS.md): fire() takes an origin and direction and
## resolves the hit with a physics raycast against the world. It returns only
## what the shooter could observe (hit position, whether something was hit). It
## does NOT accept or expose a target node to policy. Damage is applied through
## the hit body's Health/apply_damage, not back into any bot's decision inputs.
##
## All stats are DOCUMENTED PLACEHOLDERS tuned by playtest (brief §6.3). They are
## not Valorant values; no game data has been copied.

# Privileged physical result for presentation only; never a policy input.
signal kill_confirmed(victim: ActorBase, shooter: Node3D)

signal fired(from_pos: Vector3, to_pos: Vector3, hit: bool)
signal ammo_changed(in_mag: int, reserve: int)
signal reload_started
signal reload_finished

## Optional occlusion provider with segment_blocked_by_smoke(a, b) -> bool.
## When set, a shot whose line to the hit crosses active smoke is blocked (no
## damage), using the same deterministic test the perception system uses.
var occluder: Object = null

## Placeholder rifle stats. Replace with sourced values only if obtained from a
## permitted source and documented; otherwise these stay as tuned placeholders.
## Per-hitbox damage: head/body/legs. Resolved from which hitbox Area3D the shot hits.
@export var damage_head: float = 160.0
@export var damage_body: float = 40.0
@export var damage_legs: float = 34.0

@export var rounds_per_second: float = 8.0
@export var magazine_size: int = 25
@export var reserve_ammo: int = 75
@export var reload_time_s: float = 2.0
@export var range_m: float = 80.0
## Spread in radians: base, extra while firing continuously, extra while moving.
## Moving spread is very large: shooting while moving is extremely inaccurate.
@export var spread_base: float = 0.004
@export var spread_moving: float = 0.18
@export var spread_firing: float = 0.02

var in_mag: int = 0
var reserve: int = 0
var _cooldown: float = 0.0
var _is_reloading: bool = false
var _recent_fire_heat: float = 0.0  # 0..1, grows with sustained fire


const TracerScript := preload("res://weapons/tracer.gd")

## Show a visual tracer on each shot. Purely cosmetic; hit stays hitscan.
@export var show_tracer: bool = true


func _ready() -> void:
	in_mag = magazine_size
	reserve = reserve_ammo
	ammo_changed.emit(in_mag, reserve)
	if show_tracer:
		fired.connect(_spawn_tracer)


## Spawn a world-space tracer from a muzzle offset to the impact. Added under
## the current scene (not the weapon) so it stays put while the camera moves.
func _spawn_tracer(from_pos: Vector3, to_pos: Vector3, _hit: bool) -> void:
	# Offset the visible start down-right from the camera so the streak reads as
	# coming from a gun barrel instead of the center of the screen. The hit is
	# unchanged (still resolved from the true origin); this is cosmetic only.
	var basis := global_transform.basis
	var muzzle := from_pos - basis.y * 0.18 + basis.x * 0.22 - basis.z * 0.4
	var tracer: Tracer = TracerScript.new()
	var host := get_tree().current_scene
	if host == null:
		host = self
	host.add_child(tracer)
	tracer.setup(muzzle, to_pos)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	# Firing heat decays when not shooting.
	_recent_fire_heat = maxf(0.0, _recent_fire_heat - delta * 2.0)


## Can the weapon fire this instant? (off cooldown, has ammo, not reloading)
func can_fire() -> bool:
	return _cooldown <= 0.0 and in_mag > 0 and not _is_reloading


## Fire one shot. `origin`/`direction` come from the shooter's aim (camera for
## the player, aim controller for a bot). `moving` lets the caller widen spread.
## `shooter` is excluded from the raycast so you never shoot yourself.
## Returns a dictionary: { hit: bool, position: Vector3, collider: Object|null }.
## The collider is the physical hit result for the executor to apply damage; it
## is not routed into bot policy.
func fire(origin: Vector3, direction: Vector3, moving: bool, shooter: Node3D) -> Dictionary:
	var result := {"hit": false, "position": origin, "collider": null}
	if not can_fire():
		return result

	_cooldown = 1.0 / maxf(0.1, rounds_per_second)
	in_mag -= 1
	_recent_fire_heat = minf(1.0, _recent_fire_heat + 0.3)
	ammo_changed.emit(in_mag, reserve)

	var aim := _apply_spread(direction.normalized(), moving)
	var to := origin + aim * range_m

	var space: PhysicsDirectSpaceState3D = shooter.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	# Player capsules and legacy integration actors remain damageable. New
	# actors' outer capsules are skipped below so their actual hitboxes decide.
	query.collision_mask = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 6)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if shooter is CollisionObject3D:
		var excluded: Array[RID] = [shooter.get_rid()]
		for child in shooter.get_children():
			if child is CollisionObject3D:
				excluded.append(child.get_rid())
		query.exclude = excluded
	var hit := space.intersect_ray(query)
	while not hit.is_empty() and hit.collider is ActorBase and hit.collider.has_node("HitHead"):
		var excluded: Array[RID] = query.exclude
		excluded.append(hit.collider.get_rid())
		query.exclude = excluded
		hit = space.intersect_ray(query)

	var end := to
	if hit:
		end = hit.position
		result["hit"] = true
		result["position"] = hit.position
		result["collider"] = hit.collider
		# Smoke occlusion: if the line to the hit crosses active smoke, the shot
		# is stopped by the smoke and deals no damage (shared LOS rule).
		var blocked := false
		if occluder != null and occluder.has_method("segment_blocked_by_smoke"):
			blocked = occluder.segment_blocked_by_smoke(origin, hit.position)
		if not blocked:
			_apply_hit_damage(hit.collider, hit.position, shooter)
		else:
			result["hit"] = false

	fired.emit(origin, end, result["hit"])

	if in_mag == 0:
		reload()
	return result


func _apply_hit_damage(collider: Object, hit_pos: Vector3, shooter: Node3D = null) -> void:
	if collider == null:
		return
	# A hitbox Area3D carries a "hit_part" meta (head/body/legs) and links to its actor
	# via "hit_actor_path" (or an ActorBase ancestor). Resolve the part -> damage.
	var part := ""
	if collider is Node and (collider as Node).has_meta("hit_part"):
		part = String((collider as Node).get_meta("hit_part"))
	# Find the ActorBase (the hitbox's ancestor, or the collider's ancestor).
	var node := collider as Node
	var actor: ActorBase = null
	while node != null:
		if node is ActorBase:
			actor = node
			break
		node = node.get_parent()
	if actor == null:
		return
	var dmg: float
	match part:
		"head": dmg = damage_head
		"legs": dmg = damage_legs
		"body": dmg = damage_body
		_:
			# No hitbox part (e.g. hit the plain body capsule): fall back to a height split.
			var local_y := hit_pos.y - actor.global_position.y
			if local_y > 1.76:
				dmg = damage_head
			elif local_y < 0.90:
				dmg = damage_legs
			else:
				dmg = damage_body
	var was_alive := actor.is_alive
	actor.apply_damage(dmg)
	if was_alive and not actor.is_alive:
		kill_confirmed.emit(actor, shooter)


func reload() -> void:
	if _is_reloading or in_mag == magazine_size or reserve <= 0:
		return
	_is_reloading = true
	reload_started.emit()
	await get_tree().create_timer(reload_time_s).timeout
	var needed := magazine_size - in_mag
	var take := mini(needed, reserve)
	in_mag += take
	reserve -= take
	_is_reloading = false
	ammo_changed.emit(in_mag, reserve)
	reload_finished.emit()


func _apply_spread(dir: Vector3, moving: bool) -> Vector3:
	var spread := spread_base + _recent_fire_heat * spread_firing
	if moving:
		spread += spread_moving
	if spread <= 0.0:
		return dir
	# Random cone offset around the aim direction.
	var rand_yaw := randf_range(-spread, spread)
	var rand_pitch := randf_range(-spread, spread)
	var basis := Basis(Vector3.UP, rand_yaw) * Basis(Vector3.RIGHT, rand_pitch)
	return (basis * dir).normalized()
