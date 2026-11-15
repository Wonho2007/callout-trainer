extends RigidBody3D
class_name Molly
## Molly — the area_damage utility primitive (Person 1, shared mechanics).
##
## A thrown projectile that arcs under gravity, bounces off geometry, and on a
## short fuse ignites a ground zone that damages any actor standing in it over
## time. It is a generic area-damage effect (brief §6.3), a deliberate
## approximation of the tactical "deny this space" tool — not a replica of any
## specific agent kit. Both the player and bots take damage through the same
## Health path, so it is a shared mechanic, not a special case.
##
## Values come from utility/abilities.json — documented placeholders, not game
## data.

const LAYER_AREA_DAMAGE: int = 1 << 5  # layer 6 "area_damage"
## Which collision layers hold damageable actors (player=2, bots=3).
const ACTOR_MASK: int = (1 << 1) | (1 << 2)

signal ignited(source_position: Vector3)
signal expired

var radius: float = 2.5
var duration_s: float = 6.0
var damage_per_second: float = 35.0
var tick_interval_s: float = 0.5
var fuse_s: float = 0.6

var is_active: bool = false  # true once the zone is burning

var _projectile_mesh: MeshInstance3D
var _area: Area3D
var _tick_accum: float = 0.0


func setup(ability: Dictionary) -> void:
	radius = float(ability.get("radius", radius))
	duration_s = float(ability.get("duration_s", duration_s))
	damage_per_second = float(ability.get("damage_per_second", damage_per_second))
	tick_interval_s = float(ability.get("tick_interval_s", tick_interval_s))
	fuse_s = float(ability.get("deploy_delay_s", fuse_s))


func _ready() -> void:
	# Projectile physics: collide with world geometry, bounce a little.
	collision_layer = 0
	collision_mask = 1 << 0  # world
	gravity_scale = 1.0
	var phys := PhysicsMaterial.new()
	phys.bounce = 0.3
	phys.friction = 0.8
	physics_material_override = phys

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.12
	shape.shape = sphere
	add_child(shape)

	_projectile_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	_projectile_mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.4, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.35, 0.05)
	_projectile_mesh.material_override = mat
	add_child(_projectile_mesh)

	_run_fuse()


## Toss the projectile from `from` with an initial `velocity` (world space).
## Call right after instancing/adding to the tree.
func throw(from: Vector3, velocity: Vector3) -> void:
	global_position = from
	linear_velocity = velocity


func _run_fuse() -> void:
	# Fixed fuse from the throw: ignite exactly fuse_s later, wherever it is.
	await get_tree().create_timer(fuse_s).timeout
	freeze = true
	# Drop the ignition point straight down onto the floor beneath, so the fire
	# always lands flat on the ground even though the timer is absolute.
	var ground = _floor_under(global_position)
	if ground != null:
		global_position = ground as Vector3
	global_rotation = Vector3.ZERO
	if _projectile_mesh:
		_projectile_mesh.visible = false
	_ignite()
	ignited.emit(global_position)
	await get_tree().create_timer(duration_s).timeout
	is_active = false
	expired.emit()
	queue_free()


## World point on the floor directly beneath `point` (slightly above it), or
## null if no floor within reach. Used so the fire disc sits flat on the ground.
func _floor_under(point: Vector3):
	var space := get_world_3d().direct_space_state
	var from := point + Vector3(0, 0.2, 0)
	var to := point + Vector3(0, -30.0, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 0  # world geometry
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return null
	return (hit.position as Vector3) + Vector3(0, 0.05, 0)


func _ignite() -> void:
	is_active = true
	# Area3D on the area_damage layer; its mask detects actor bodies for damage.
	_area = Area3D.new()
	_area.collision_layer = LAYER_AREA_DAMAGE
	_area.collision_mask = ACTOR_MASK
	_area.monitoring = true
	add_child(_area)

	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 1.0  # a shallow ground zone
	shape.shape = cyl
	_area.add_child(shape)

	# Translucent orange visual so the fire zone reads in-engine.
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.3
	mesh_instance.mesh = mesh
	mesh_instance.position.y = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.4, 0.1, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.35, 0.05)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_area.add_child(mesh_instance)


func _physics_process(delta: float) -> void:
	if not is_active or _area == null:
		return
	_tick_accum += delta
	if _tick_accum < tick_interval_s:
		return
	_tick_accum = 0.0
	# Damage every actor currently inside the zone for one tick's worth.
	var dmg := damage_per_second * tick_interval_s
	for body in _area.get_overlapping_bodies():
		var actor := _actor_of(body)
		if actor != null:
			actor.apply_damage(dmg)


## Find an ActorBase at `body` (the body or an ancestor), or null.
func _actor_of(body: Node) -> ActorBase:
	var node := body
	while node != null:
		if node is ActorBase:
			return node
		node = node.get_parent()
	return null


## True if a point is inside the burning zone (for debug / perception queries).
func contains_point(point: Vector3) -> bool:
	if not is_active:
		return false
	var d := Vector2(point.x - global_position.x, point.z - global_position.z)
	return d.length() <= radius
