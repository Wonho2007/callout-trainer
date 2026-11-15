extends CharacterBody3D
class_name ActorBase
## Shared actor base (Person 1, shared mechanics).
##
## The movement/physics rules the player and all bots share. Bots (Person 2)
## reuse this as their actor component and drive it through intent: set a desired
## move direction or a path to follow, and the actor resolves gravity, speed and
## collision with move_and_slide(). This is the physical executor side only.
##
## Fairness boundary (AGENTS.md): this base holds NO references to other actors
## and exposes none. Bot policy must decide intent from its own delayed
## observations/beliefs (Person 2/3), not by reading other actors here. Movement
## intent is a direction or a world point, never another actor's live transform.
##
## All speeds/values are placeholders tuned by playtest (brief §6.3).

@export var run_speed: float = 6.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5

## Dash: a short horizontal impulse burst. Respects collision (move_and_slide),
## so an actor cannot dash through walls. Distance = dash_speed * dash_time_s = 11.0 m.
@export var dash_speed: float = 61.11
@export var dash_time_s: float = 0.18
@export var dash_cooldown_s: float = 2.5

enum MoveMode { RUN, WALK, CROUCH }

## Emitted when a dash starts (for the event bus / feedback). No hidden truth.
signal dashed(direction: Vector3)

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

## Desired horizontal move direction in world space (normalized). Zero = stop.
## Bots and the player set this each tick; _physics_process applies it.
var move_dir: Vector3 = Vector3.ZERO
var move_mode: int = MoveMode.RUN
var _want_jump: bool = false

## Dash state.
var _dash_dir: Vector3 = Vector3.ZERO
var _dash_remaining: float = 0.0
var _dash_cooldown_remaining: float = 0.0

## Optional health component child named "Health", if present.
@onready var health: Health = get_node_or_null("Health")

## Utility system reference for flash/wave sampling and smoke occlusion checks.
var utility_system: Node = null:
	set(val):
		utility_system = val
		_bind_utility()

## Blind / Flash state (seconds remaining). While > 0, the actor is blinded.
var blind_remaining: float = 0.0
var blind_kind: String = "flashed"
var _actor_applied_waves: Dictionary = {}

var _blind_indicator: Node3D = null
var _blind_label: Label3D = null
var _blind_aura: Node3D = null
var _blind_circle: MeshInstance3D = null
var _circle_mat: StandardMaterial3D = null
var _halo_mat: StandardMaterial3D = null
var _visor_mat: StandardMaterial3D = null

static var _cached_circle_textures: Dictionary = {}

## Emitted when this actor dies (combatant state only). Carries no hidden
## truth — just that this actor died. Consumers: round logic, and Person 3's
## grader via permitted event forwarding. Does NOT expose a killer.
signal died

## False once dead: a dead actor stops moving as a combatant. Death does not
## free the node and (for the player) does not disable the comms/input channel —
## the player must still be able to report after dying (COMMUNICATION_COACHING).
var is_alive: bool = true


func _ready() -> void:
	if health:
		health.died.connect(_on_health_died)
	_setup_blind_indicator()
	_bind_utility()


func _on_health_died() -> void:
	is_alive = false
	blind_remaining = 0.0
	_update_blind_visuals()
	move_dir = Vector3.ZERO
	died.emit()


func _physics_process(delta: float) -> void:
	if _dash_cooldown_remaining > 0.0:
		_dash_cooldown_remaining = maxf(0.0, _dash_cooldown_remaining - delta)

	if blind_remaining > 0.0:
		blind_remaining = maxf(0.0, blind_remaining - delta)
		_update_blind_visuals()
		if _blind_aura and is_alive:
			_blind_aura.rotate_y(delta * 4.0)
		if _blind_circle and is_alive:
			var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.009)
			_blind_circle.scale = Vector3(pulse, pulse, pulse)

	_sample_utility_waves()

	# A dead combatant does not move, but still falls so it rests on the floor.
	if not is_alive:
		_dash_remaining = 0.0
		_apply_gravity(delta)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	_apply_gravity(delta)

	# An active dash overrides normal horizontal movement with an impulse burst;
	# move_and_slide still resolves collision, so you cannot dash through walls.
	if _dash_remaining > 0.0:
		_dash_remaining -= delta
		velocity.x = _dash_dir.x * dash_speed
		velocity.z = _dash_dir.z * dash_speed
		move_and_slide()
		return

	if _want_jump and is_on_floor():
		velocity.y = jump_velocity
	_want_jump = false

	var speed := _speed_for_mode()
	var dir := move_dir
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


func _speed_for_mode() -> float:
	match move_mode:
		MoveMode.WALK: return walk_speed
		MoveMode.CROUCH: return crouch_speed
		_: return run_speed


## --- intent API (used by the player's input and by Person 2's bot policy) ---

## Set the desired world-space move direction (y ignored). Zero to stop.
func set_move_dir(dir: Vector3) -> void:
	move_dir = dir


## Request a jump on the next physics step (applied only if on the floor).
func request_jump() -> void:
	_want_jump = true


## Dash in a world-space horizontal direction (y ignored). Falls back to the
## actor's current facing if the direction is ~zero. No-op while dead, already
## dashing, or on cooldown. Shared by the player and bots.
func dash(direction: Vector3) -> bool:
	if not is_alive or _dash_remaining > 0.0 or _dash_cooldown_remaining > 0.0:
		return false
	var d := direction
	d.y = 0.0
	if d.length() < 0.001:
		d = -global_transform.basis.z  # current facing
		d.y = 0.0
	_dash_dir = d.normalized()
	_dash_remaining = dash_time_s
	_dash_cooldown_remaining = dash_cooldown_s
	dashed.emit(_dash_dir)
	return true


## True if a dash can be triggered right now (alive, not dashing, off cooldown).
func can_dash() -> bool:
	return is_alive and _dash_remaining <= 0.0 and _dash_cooldown_remaining <= 0.0


## Remaining dash cooldown in seconds (0 = ready). For HUD/feedback.
func dash_cooldown_left() -> float:
	return _dash_cooldown_remaining


## Move toward a world-space point. Returns the distance remaining. Callers
## (e.g. a bot following a navmesh path) step through path points themselves;
## this only turns a target point into a move direction for this tick.
func move_toward_point(point: Vector3) -> float:
	var to := point - global_position
	to.y = 0.0
	set_move_dir(to)
	return to.length()


## Apply damage via the Health component (if any). The physical executor side;
## weapons and area effects call this. Does nothing if no Health or already dead.
func apply_damage(amount: float) -> void:
	if health:
		health.apply_damage(amount)


## Place the actor at a spawn marker (position + yaw). Resets velocity/health
## and revives the combatant (used on round restart).
func teleport_to(marker: Marker3D) -> void:
	global_position = marker.global_position
	rotation.y = marker.rotation.y
	velocity = Vector3.ZERO
	is_alive = true
	blind_remaining = 0.0
	_actor_applied_waves.clear()
	_update_blind_visuals()
	if health:
		health.reset()


## Apply blind/flash to this actor for a duration in seconds.
func apply_blind(duration_s: float, kind: String = "flashed") -> void:
	if not is_alive:
		return
	if duration_s <= 0.0:
		blind_remaining = 0.0
		_update_blind_visuals()
		return
	blind_remaining = maxf(blind_remaining, duration_s)
	blind_kind = kind
	_update_blind_visuals()


## True if the actor is currently alive and blinded/flashed.
func is_blinded() -> bool:
	return is_alive and blind_remaining > 0.0


## Evaluate an active/detonated flash against this actor's eyes and facing.
## Returns the applied blind duration, or 0.0 if not affected.
func check_flash(flash: Node3D) -> float:
	if not is_alive or flash == null or not is_instance_valid(flash):
		return 0.0
	var eye := global_position + Vector3(0, 1.86, 0)
	var forward := -global_transform.basis.z
	var has_los := _has_clear_los_to(flash.global_position)
	var dur: float = flash.blind_duration_for(eye, forward, has_los) if flash.has_method("blind_duration_for") else 0.0
	if dur > 0.0:
		apply_blind(dur, "flashed")
	return dur


## Line of sight check from actor to target position, respecting world geometry and smoke.
## Checks multiple sample points (eye & chest to target & mid-air burst) to prevent
## false occlusions from low floor geometry or waist-high edges.
func _has_clear_los_to(target_pos: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var space := get_world_3d().direct_space_state
	var my_rid := get_rid()

	var viewer_points: Array[Vector3] = [
		global_position + Vector3(0, 1.86, 0),  # eye
		global_position + Vector3(0, 1.33, 0)   # chest
	]
	var target_points: Array[Vector3] = [
		target_pos,                             # exact pos
		target_pos + Vector3(0, 0.5, 0)         # flash light burst center
	]

	for v_pt in viewer_points:
		for t_pt in target_points:
			var to_t := t_pt - v_pt
			var dist := to_t.length()
			if dist < 0.1:
				return true
			var start := v_pt + (to_t / dist) * minf(0.35, dist * 0.4)
			var query := PhysicsRayQueryParameters3D.create(start, t_pt)
			query.collision_mask = 1 << 0  # world geometry
			query.collide_with_bodies = true
			query.exclude = [my_rid]
			var hit := space.intersect_ray(query)
			if not hit:
				if utility_system and utility_system.has_method("segment_blocked_by_smoke"):
					if not utility_system.segment_blocked_by_smoke(v_pt, t_pt):
						return true
				else:
					return true
	return false


func _bind_utility() -> void:
	if utility_system == null or not is_inside_tree():
		return
	if utility_system.has_signal("flash_detonated"):
		if not utility_system.flash_detonated.is_connected(_on_utility_flash_detonated):
			utility_system.flash_detonated.connect(_on_utility_flash_detonated)


func _on_utility_flash_detonated(flash: Node3D, _pos: Vector3) -> void:
	check_flash(flash)


## Sample passing blind waves (e.g. G ability).
func _sample_utility_waves() -> void:
	if utility_system == null or not is_alive or not is_inside_tree():
		return
	if not utility_system.has_method("active_blind_waves"):
		return
	var eye := global_position + Vector3(0, 1.86, 0)
	var forward := -global_transform.basis.z
	var waves = utility_system.active_blind_waves()
	for wave in waves:
		if not is_instance_valid(wave) or _actor_applied_waves.has(wave.get_instance_id()):
			continue
		var has_los := _has_clear_los_to(wave.global_position)
		var dur: float = wave.passing_blind_duration_for(eye, forward, has_los) if wave.has_method("passing_blind_duration_for") else 0.0
		if dur > 0.0:
			_actor_applied_waves[wave.get_instance_id()] = true
			apply_blind(dur + 1.0, "blinded")


func _setup_blind_indicator() -> void:
	# Don't attach visual billboard indicator if this actor has a player camera.
	if has_node("Camera3D"):
		return

	_blind_indicator = Node3D.new()
	_blind_indicator.name = "BlindIndicator"
	_blind_indicator.visible = false
	add_child(_blind_indicator)

	# 1) Large billboarded glowing circle on the head
	_blind_circle = MeshInstance3D.new()
	_blind_circle.name = "BlindCircle"
	var q := QuadMesh.new()
	q.size = Vector2(1.15, 1.15)
	_blind_circle.mesh = q
	_blind_circle.position = Vector3(0, 2.15, 0)

	_blind_circle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_circle_mat = StandardMaterial3D.new()
	_circle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_circle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_circle_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_circle_mat.render_priority = 10
	_circle_mat.no_depth_test = true
	_circle_mat.albedo_texture = _get_circle_texture("flashed")
	_blind_circle.material_override = _circle_mat
	_blind_indicator.add_child(_blind_circle)

	# 2) Floating billboard status text above the circle
	_blind_label = Label3D.new()
	_blind_label.name = "BlindLabel"
	_blind_label.text = "✦ FLASHED ✦"
	_blind_label.position = Vector3(0, 2.80, 0)
	_blind_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_blind_label.no_depth_test = true
	_blind_label.render_priority = 11
	_blind_label.font_size = 36
	_blind_label.modulate = Color(1.0, 0.95, 0.25, 1.0)
	_blind_label.outline_size = 8
	_blind_label.outline_modulate = Color(0.06, 0.06, 0.03, 0.95)
	_blind_indicator.add_child(_blind_label)

	# 3) 3D visual blinding aura at head level
	_blind_aura = Node3D.new()
	_blind_aura.name = "BlindAura"
	_blind_indicator.add_child(_blind_aura)

	# Glowing blinding visor over the eyes/face
	var visor := MeshInstance3D.new()
	var v_mesh := BoxMesh.new()
	v_mesh.size = Vector3(0.50, 0.16, 0.10)
	visor.mesh = v_mesh
	visor.position = Vector3(0, 1.86, -0.24)
	_visor_mat = StandardMaterial3D.new()
	_visor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_visor_mat.no_depth_test = true
	_visor_mat.render_priority = 9
	_visor_mat.albedo_color = Color(1.0, 0.95, 0.35, 0.95)
	visor.material_override = _visor_mat
	_blind_aura.add_child(visor)

	# Rotating 3D flash halo above head
	var halo := MeshInstance3D.new()
	var h_mesh := TorusMesh.new()
	h_mesh.inner_radius = 0.22
	h_mesh.outer_radius = 0.34
	halo.mesh = h_mesh
	halo.position = Vector3(0, 2.06, 0)
	_halo_mat = StandardMaterial3D.new()
	_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo_mat.no_depth_test = true
	_halo_mat.render_priority = 9
	_halo_mat.albedo_color = Color(1.0, 0.9, 0.2, 0.95)
	halo.material_override = _halo_mat
	_blind_aura.add_child(halo)


func _update_blind_visuals() -> void:
	if _blind_indicator == null:
		return
	var active := is_alive and blind_remaining > 0.0
	_blind_indicator.visible = active
	if not active:
		return
	if _circle_mat:
		_circle_mat.albedo_texture = _get_circle_texture(blind_kind)
	if _blind_label:
		if blind_kind == "flashed":
			_blind_label.text = "✦ FLASHED %.1fs ✦" % maxf(0.1, blind_remaining)
			_blind_label.modulate = Color(1.0, 0.95, 0.25, 1.0)
			if _halo_mat:
				_halo_mat.albedo_color = Color(1.0, 0.9, 0.2, 0.95)
			if _visor_mat:
				_visor_mat.albedo_color = Color(1.0, 0.95, 0.35, 0.95)
		else:
			_blind_label.text = "✦ BLINDED %.1fs ✦" % maxf(0.1, blind_remaining)
			_blind_label.modulate = Color(0.55, 0.88, 1.0, 1.0)
			if _halo_mat:
				_halo_mat.albedo_color = Color(0.4, 0.85, 1.0, 0.95)
			if _visor_mat:
				_visor_mat.albedo_color = Color(0.5, 0.88, 1.0, 0.95)


static func _get_circle_texture(kind: String) -> ImageTexture:
	if _cached_circle_textures.has(kind):
		return _cached_circle_textures[kind]
	var col := Color(1.0, 0.95, 0.2) if kind == "flashed" else Color(0.4, 0.85, 1.0)
	var tex := _generate_circle_texture(128, col)
	_cached_circle_textures[kind] = tex
	return tex


static func _generate_circle_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var r_outer := size * 0.46
	var r_ring_in := size * 0.30
	var r_center := size * 0.10

	for y in range(size):
		for x in range(size):
			var dist := center.distance_to(Vector2(x + 0.5, y + 0.5))
			if dist > r_outer + 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif dist >= r_ring_in:
				var edge_out := clampf((r_outer - dist) / 1.5, 0.0, 1.0)
				var edge_in := clampf((dist - r_ring_in) / 1.5, 0.0, 1.0)
				var a := minf(edge_out, edge_in)
				if dist >= r_outer - 3.0 or dist <= r_ring_in + 3.0:
					img.set_pixel(x, y, Color(0.05, 0.05, 0.02, a * 0.95))
				else:
					img.set_pixel(x, y, Color(color.r, color.g, color.b, a))
			elif dist <= r_center:
				var edge_c := clampf((r_center - dist) / 1.5, 0.0, 1.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, edge_c * 0.95))
			else:
				var t := (dist - r_center) / (r_ring_in - r_center)
				var core_a := lerpf(0.35, 0.12, t)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, core_a))
	return ImageTexture.create_from_image(img)
