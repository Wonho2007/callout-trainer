extends RigidBody3D
class_name Flash
## Flash — the blind utility primitive (Person 1, shared mechanics).
##
## A small projectile tossed from the thrower that arcs under gravity, bounces
## off geometry, and detonates after a short delay. On detonation it blinds any
## agent that can see it within range, with duration scaled by how directly the
## agent looks at it. This node computes a per-viewer blind amount from geometry;
## it does NOT reach into bot policy. Person 2's perception applies the blind to
## bots; Person 1 applies it to the player (first-person whiteout). Fallback bots
## obey the same rule.
##
## Values come from utility/abilities.json — documented placeholders, not
## Valorant data.

signal detonated(source_position: Vector3)
signal expired

var trigger_delay_s: float = 0.75
var max_blind_s: float = 5.0
var min_blind_s: float = 3.0
var range_m: float = 30.0

var is_active: bool = false
var _mesh: MeshInstance3D


func setup(ability: Dictionary) -> void:
	trigger_delay_s = float(ability.get("trigger_delay_s", trigger_delay_s))
	max_blind_s = float(ability.get("max_blind_s", max_blind_s))
	min_blind_s = float(ability.get("min_blind_s", min_blind_s))
	range_m = float(ability.get("range_m", range_m))


func _ready() -> void:
	# Projectile physics: collide with world geometry, bounce a little.
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
	mat.albedo_color = Color(0.95, 0.9, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.85, 0.3)
	_mesh.material_override = mat
	add_child(_mesh)

	_run_fuse()


## Toss the projectile from `from` with an initial `velocity` (world space).
## Call right after instancing/adding to the tree.
func throw(from: Vector3, velocity: Vector3) -> void:
	global_position = from
	linear_velocity = velocity


func _run_fuse() -> void:
	await get_tree().create_timer(trigger_delay_s).timeout
	# Stop moving and detonate where it came to rest.
	freeze = true
	is_active = true
	if _mesh:
		_mesh.visible = false
	detonated.emit(global_position)
	# Hold briefly so listeners can sample the blind, then expire.
	await get_tree().create_timer(0.1).timeout
	is_active = false
	expired.emit()
	queue_free()


## Blind duration (seconds) for a viewer at `viewer_pos` facing `viewer_forward`
## (a normalized direction). Returns 0 if out of range, behind the viewer, or
## without line of sight (pass has_los=false). Duration scales from min_blind_s
## (glancing) to max_blind_s (looking straight at it).
func blind_duration_for(viewer_pos: Vector3, viewer_forward: Vector3, has_los: bool) -> float:
	if not has_los:
		return 0.0
	var to_source := global_position - viewer_pos
	var dist := to_source.length()
	if dist > range_m or dist < 0.001:
		return 0.0
	var dir := to_source / dist
	# How directly the viewer looks at the flash: 1.0 = straight on, <=0 behind.
	var facing := viewer_forward.normalized().dot(dir)
	var range_factor := clampf(1.0 - (dist / range_m), 0.0, 1.0)

	# Close detonation (< 8m): concussion and light bounce cause a strong blind even when turned
	if dist < 8.0:
		var close_facing_floor := lerpf(0.65, 0.20, dist / 8.0)
		facing = maxf(facing, close_facing_floor)

	if facing <= 0.0:
		# Turned away at medium distance: glancing blind
		return maxf(1.5, min_blind_s * 0.6 * range_factor)

	var strength := clampf(facing, 0.0, 1.0) * range_factor
	return lerpf(min_blind_s, max_blind_s, clampf(strength, 0.0, 1.0))
