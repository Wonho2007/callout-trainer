extends Node3D
class_name Smoke
## Smoke — the los_blocker utility primitive (Person 1, shared mechanics).
##
## A timed spherical volume that blocks vision raycasts. It lives on the
## dedicated "smoke" collision layer (layer 5) so the perception system
## (Person 2) and the shared weapon can test line-of-sight against it separately
## from world geometry. This node is the physical effect only; it does not
## decide what anyone can see.
##
## Deploy: the smoke stays where it is aimed. If the aimed point is floating in
## open air, it falls straight down at a constant slow velocity until it lands
## on the ground; if the aimed point is already on a surface, there is no fall.
## Occlusion is gated on the "active" flag so it only blocks once settled. The
## geometric tests use this node's fixed settled center (global_position), not
## the animating visual body.
##
## Values come from the utility definitions (utility/abilities.json), documented
## placeholders tuned by playtest — not Valorant data.

const LAYER_SMOKE: int = 1 << 4  # layer 5 "smoke"
const DROP_SPEED: float = 4.0    # constant fall speed (m/s), slow and steady

signal expired

var radius: float = 3.0
var duration_s: float = 12.0

## False while falling/settling; occlusion tests return false until settled.
var is_active: bool = false

var _body: StaticBody3D


## Configure from an ability definition dictionary before adding to the tree.
func setup(ability: Dictionary) -> void:
	radius = float(ability.get("radius", radius))
	duration_s = float(ability.get("duration_s", duration_s))


## Deploy at `settle_center` (the fixed resting center used by all tests),
## visually falling from `start_center` at a constant speed. If the two are the
## same (aimed at a surface), there is no fall. Call right after adding to tree.
func deploy(start_center: Vector3, settle_center: Vector3) -> void:
	if is_inside_tree():
		global_position = settle_center
	else:
		position = settle_center
	_build()
	# Offset the visual body up to the start, then fall it to the settle center.
	var drop := start_center - settle_center
	_fall(drop)


func _build() -> void:
	# Collision body on the smoke layer: raycasts that test the smoke mask will
	# hit this; it does not collide with or block movement (mask 0, layer only).
	_body = StaticBody3D.new()
	_body.collision_layer = LAYER_SMOKE
	_body.collision_mask = 0
	add_child(_body)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	_body.add_child(shape)

	# Opaque visual with double-sided rendering (CULL_DISABLED).
	# This ensures the interior surface forms a closed dome when standing inside,
	# completely cutting off all vision of the world outside the smoke.
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.25, 0.28, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.95
	mesh_instance.material_override = mat
	_body.add_child(mesh_instance)


## Fall the visual body from a local offset down to zero at constant velocity,
## then activate occlusion and start the lifetime. Zero offset = no fall.
func _fall(offset: Vector3) -> void:
	_body.position = offset
	var dist := offset.length()
	if dist > 0.01:
		var fall_time := dist / DROP_SPEED
		var tween := create_tween()
		tween.tween_property(_body, "position", Vector3.ZERO, fall_time) \
			.set_trans(Tween.TRANS_LINEAR)
		await tween.finished
	is_active = true
	await get_tree().create_timer(duration_s).timeout
	expired.emit()
	queue_free()


## True if the straight segment from `a` to `b` passes through this smoke
## sphere. Returns false until the smoke has settled. Perception (Person 2) and
## the weapon use this to decide occlusion; it uses the fixed settled center.
func blocks_segment(a: Vector3, b: Vector3) -> bool:
	if not is_active:
		return false
	var center := global_position
	var ab := b - a
	var t := 0.0
	if ab.length_squared() > 0.0001:
		t = clampf((center - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var closest := a + ab * t
	return closest.distance_to(center) <= radius


## True if `point` is inside this settled smoke sphere (used for in-smoke fog).
func contains_point(point: Vector3) -> bool:
	if not is_active:
		return false
	return point.distance_to(global_position) <= radius
