extends RigidBody3D
class_name ScanOrb
## Scan orb — a generic recon utility (Person 1, shared mechanics).
##
## A thrown orb that arcs, bounces, and after a short fuse scans its radius for
## enemies. It reveals an enemy ONLY if the orb has clear line of sight to it
## within range — a fair sensor, using the same visibility rules as perception,
## not a wallhack. Revealed contacts are LAST-KNOWN marks that decay; they are
## not live tracking. This is an original ability, not a replica of any agent kit.
##
## Fairness (AGENTS.md, §6.4/§6.12): the scan performs real line-of-sight checks
## from the orb and only reports what it could actually see. It reports to the
## player's HUD/minimap as decaying marks; it must NOT be wired into bot policy
## as hidden truth. Values are documented placeholders.

## Emitted on scan with the contacts the orb could actually see: an array of
## { position: Vector3, reveal_until: float } (reveal_until in engine seconds).
signal scanned(contacts: Array)
signal expired

var fuse_s: float = 0.8
var scan_radius_m: float = 14.0
var reveal_duration_s: float = 4.0

## Enemies to test against (set by the thrower). The orb reads positions only to
## run its own LOS check; it does not expose these nodes anywhere else.
var _targets: Array = []
var _mesh: MeshInstance3D


func setup(ability: Dictionary) -> void:
	fuse_s = float(ability.get("fuse_s", fuse_s))
	scan_radius_m = float(ability.get("scan_radius_m", scan_radius_m))
	reveal_duration_s = float(ability.get("reveal_duration_s", reveal_duration_s))


## Throw from `from` with `velocity`, scanning against `targets` on detonation.
func throw(from: Vector3, velocity: Vector3, targets: Array) -> void:
	global_position = from
	linear_velocity = velocity
	_targets = targets


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 0  # world
	gravity_scale = 1.0
	var phys := PhysicsMaterial.new()
	phys.bounce = 0.4
	phys.friction = 0.6
	physics_material_override = phys

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.12
	shape.shape = sphere
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	_mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.9, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.8)
	_mesh.material_override = mat
	add_child(_mesh)

	_run_fuse()


func _run_fuse() -> void:
	await get_tree().create_timer(fuse_s).timeout
	freeze = true
	if _mesh:
		_mesh.visible = false
	scanned.emit(_scan())
	expired.emit()
	queue_free()


## Return last-known marks for every target within range that the orb has clear
## line of sight to (fair sensor; nothing behind cover from the orb is revealed).
func _scan() -> Array:
	var contacts: Array = []
	var now := Time.get_ticks_msec() / 1000.0
	var space := get_world_3d().direct_space_state
	var origin := global_position
	for t in _targets:
		if t == null or not is_instance_valid(t):
			continue
		var tp: Vector3 = t.global_position
		if origin.distance_to(tp) > scan_radius_m:
			continue
		# Line of sight from the orb to the target's torso (world geometry only).
		var query := PhysicsRayQueryParameters3D.create(origin + Vector3(0, 0.2, 0),
			tp + Vector3(0, 1.0, 0))
		query.collision_mask = 1 << 0
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			contacts.append({
				"position": tp,
				"reveal_until": now + reveal_duration_s,
			})
	return contacts
