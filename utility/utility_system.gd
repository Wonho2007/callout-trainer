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

@export_file("*.json") var definitions_path: String = "res://utility/abilities.json"

var _defs: Dictionary = {}
var _smokes: Array[Smoke] = []
var _flashes: Array[Flash] = []


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


## Deploy a smoke aimed at world point `at`. The smoke stays where it is aimed;
## if the aimed point is floating in open air, it falls straight down until it
## lands on the ground. Returns the Smoke, or null if undefined.
func throw_smoke(at: Vector3) -> Smoke:
	if not _defs.has("smoke"):
		return null
	var smoke: Smoke = SmokeScript.new()
	smoke.setup(_defs["smoke"])
	add_child(smoke)

	# The sphere center sits one radius above a surface so it rests on it.
	var start_center := at + Vector3(0, smoke.radius, 0)
	# Raycast straight down from the aimed point to find the ground below.
	var ground_y = _ground_below(at)
	var settle_center := start_center
	if ground_y != null:
		settle_center = Vector3(at.x, (ground_y as float) + smoke.radius, at.z)

	smoke.deploy(start_center, settle_center)
	_smokes.append(smoke)
	smoke.expired.connect(func(): _smokes.erase(smoke))
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
	flash.expired.connect(func(): _flashes.erase(flash))
	return flash


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
