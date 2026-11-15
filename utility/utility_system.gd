extends Node3D
class_name UtilitySystem
## Utility system (Person 1, shared mechanics).
##
## Loads the data-driven utility definitions and spawns smoke/flash effects from
## them. Keeps the live effects so the perception system (Person 2) and the
## shared weapon can query them for line-of-sight occlusion and blind. This is
## the spawn/registry side only — it does not implement bot vision.

const SmokeScript := preload("res://utility/smoke.gd")
const FlashScript := preload("res://utility/flash.gd")
const MollyScript := preload("res://utility/molly.gd")
const BlindWaveScript := preload("res://utility/blind_wave.gd")
const ScanOrbScript := preload("res://utility/scan_orb.gd")
const ReconOutlineScript := preload("res://utility/recon_outline.gd")

# Privileged damage attribution; not exposed to policy.
signal kill_confirmed(victim: ActorBase, thrower_id: String)
## Emitted when utility is deployed, for the privileged recorder/grader (not a
## policy input). Carries the ability id, thrower id and world position.
signal deployed(ability_id: String, thrower_id: String, position: Vector3)
## Emitted when a flash or blind wave detonates in the world, carrying the effect node and position.
signal flash_detonated(flash: Flash, position: Vector3)
signal blind_wave_detonated(wave: BlindWave, position: Vector3)

@export_file("*.json") var definitions_path: String = "res://utility/abilities.json"

var _defs: Dictionary = {}
var _smokes: Array[Smoke] = []
var _flashes: Array[Flash] = []
var _mollies: Array[Molly] = []
var _blind_waves: Array[BlindWave] = []
## Decaying last-known recon marks for the player's HUD/minimap (not bot policy).
## Each: { position: Vector3, reveal_until: float }.
var _recon_marks: Array = []


func _ready() -> void:
	_load_defs(definitions_path)


func _load_defs(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_error("utility_system: definitions not found: %s" % path)
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("utility_system: JSON parse error in %s" % path)
		return
	for ability in json.data.get("abilities", []):
		_defs[String(ability.get("id", ""))] = ability


## Deploy a smoke aimed at world point `at`, settling 35% below the floor.
## Optional thrower identity preserves bot/player attribution in the event log.
func throw_smoke(at: Vector3, thrower_id: String = "player") -> Smoke:

	if not _defs.has("smoke"):
		return null
	var smoke: Smoke = SmokeScript.new()
	smoke.setup(_defs["smoke"])
	add_child(smoke)

	# Find the ground below the aimed point.
	var ground_y = _ground_below(at)
	var gy: float = (ground_y as float) if ground_y != null else at.y

	# Bottom 35% of the sphere (diameter 2 * radius) is submerged in the ground:
	# Submerged height = 0.35 * (2.0 * radius) = 0.70 * radius.
	# Settle center Y = ground_y - 0.70 * radius + radius = ground_y + 0.30 * radius.
	var settle_center := Vector3(at.x, gy + 0.30 * smoke.radius, at.z)

	# Start above ground so the smoke visibly descends into the ground until settling.
	var start_y: float = maxf(at.y + smoke.radius, gy + smoke.radius)
	var start_center := Vector3(at.x, start_y, at.z)

	smoke.deploy(start_center, settle_center)
	_smokes.append(smoke)
	smoke.expired.connect(func(): _smokes.erase(smoke))
	deployed.emit("smoke", thrower_id, settle_center)
	return smoke


## Y of the first world surface below `point`, or null if none within reach.
func _ground_below(point: Vector3):
	var space := get_world_3d().direct_space_state
	var from := point + Vector3(0, 0.05, 0)
	var to := point + Vector3(0, -50.0, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 0  # world geometry only
	var hit := space.intersect_ray(query)
	if hit:
		return (hit.position as Vector3).y
	return null


## Toss a flash projectile from `from` with an initial `velocity`. Returns the
## Flash, or null if undefined.
func throw_flash(from: Vector3, velocity: Vector3) -> Flash:
	if not _defs.has("flash"):
		return null
	var flash: Flash = FlashScript.new()
	flash.setup(_defs["flash"])
	add_child(flash)
	flash.throw(from, velocity)
	_flashes.append(flash)
	flash.detonated.connect(func(pos):
		flash_detonated.emit(flash, pos)
	)
	flash.expired.connect(func(): _flashes.erase(flash))
	deployed.emit("flash", "player", from)
	return flash


## Toss a molly (area_damage) projectile from `from` with an initial `velocity`.
## It arcs, bounces, and ignites a damaging ground zone where it rests. Returns
## the Molly, or null if undefined.
func throw_molly(from: Vector3, velocity: Vector3, thrower_id: String = "player") -> Molly:
	if not _defs.has("molly"):
		return null
	var molly: Molly = MollyScript.new()
	molly.setup(_defs["molly"])
	add_child(molly)
	molly.throw(from, velocity)
	_mollies.append(molly)
	molly.expired.connect(func(): _mollies.erase(molly))
	molly.kill_confirmed.connect(func(victim: ActorBase): kill_confirmed.emit(victim, thrower_id))
	molly.ignited.connect(func(pos): deployed.emit("molly", thrower_id, pos))
	return molly


## Launch a blind wave from `from` travelling along horizontal `direction`.
## Returns the BlindWave, or null if undefined.
func throw_blind_wave(from: Vector3, direction: Vector3) -> BlindWave:
	if not _defs.has("blind_wave"):
		return null
	var wave: BlindWave = BlindWaveScript.new()
	wave.setup(_defs["blind_wave"])
	add_child(wave)
	wave.launch(from, direction)
	_blind_waves.append(wave)
	wave.expired.connect(func(): _blind_waves.erase(wave))
	wave.detonated.connect(func(pos):
		blind_wave_detonated.emit(wave, pos)
		deployed.emit("blind_wave", "player", pos)
	)
	return wave


## Throw a scan orb from `from` with `velocity`, scanning against `targets` on
## detonation. Revealed contacts (fair LOS only) become decaying recon marks.
## Returns the ScanOrb, or null if undefined.
func throw_scan_orb(from: Vector3, velocity: Vector3, targets: Array) -> ScanOrb:
	if not _defs.has("scan_orb"):
		return null
	var orb: ScanOrb = ScanOrbScript.new()
	orb.setup(_defs["scan_orb"])
	add_child(orb)
	orb.throw(from, velocity, targets)
	orb.scanned.connect(_on_scan)
	orb.scanned.connect(func(_c): deployed.emit("scan_orb", "player", orb.global_position))
	return orb


func _on_scan(contacts: Array) -> void:
	for c in contacts:
		_recon_marks.append(c)
		# Spawn a decaying through-wall outline at each scanned position
		# (player-only visual snapshot of fair info; not a bot-policy input).
		var outline: ReconOutline = ReconOutlineScript.new()
		add_child(outline)
		var dur := float(c.get("reveal_until", 0.0)) - (Time.get_ticks_msec() / 1000.0)
		outline.setup(c["position"], maxf(0.1, dur))


## Current, non-expired recon marks for the player's HUD/minimap. Prunes stale
## ones. This is a player-facing last-known display, never a bot-policy input.
func recon_marks() -> Array:
	var now := Time.get_ticks_msec() / 1000.0
	var live: Array = []
	for m in _recon_marks:
		if float(m.get("reveal_until", 0.0)) > now:
			live.append(m)
	_recon_marks = live
	return live


## Live blind waves, for the player/perception to query on detonation.
func active_blind_waves() -> Array[BlindWave]:
	return _blind_waves


## True if any active smoke blocks the straight segment a -> b. Perception and
## the weapon call this to add smoke occlusion on top of world geometry.
func segment_blocked_by_smoke(a: Vector3, b: Vector3) -> bool:
	for smoke in _smokes:
		if is_instance_valid(smoke) and smoke.blocks_segment(a, b):
			return true
	return false


## True if `point` is inside any active smoke (for the in-smoke camera fog).
func point_in_smoke(point: Vector3) -> bool:
	for smoke in _smokes:
		if is_instance_valid(smoke) and smoke.contains_point(point):
			return true
	return false


## Live effects, for perception/debug to read. Not a policy input path.
func active_smokes() -> Array[Smoke]:
	return _smokes


func active_flashes() -> Array[Flash]:
	return _flashes


func clear_effects() -> void:
	# Round restart: remove prior-round blockers/projectiles and private marks.
	for effect in get_children():
		effect.queue_free()
	_smokes.clear()
	_flashes.clear()
	_mollies.clear()
	_blind_waves.clear()
	_recon_marks.clear()
