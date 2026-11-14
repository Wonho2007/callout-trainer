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
## Values come from the utility definitions (utility/abilities.json), documented
## placeholders tuned by playtest — not Valorant data.

const LAYER_SMOKE: int = 1 << 4  # layer 5 "smoke"

signal expired

var radius: float = 3.0
var duration_s: float = 12.0

var _body: StaticBody3D


## Configure from an ability definition dictionary before adding to the tree.
func setup(ability: Dictionary) -> void:
	radius = float(ability.get("radius", radius))
	duration_s = float(ability.get("duration_s", duration_s))


func _ready() -> void:
	_build()
	await get_tree().create_timer(duration_s).timeout
	expired.emit()
	queue_free()


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

	# Translucent visual so the smoke reads in-engine.
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.9, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = mat
	_body.add_child(mesh_instance)


## True if the straight segment from `a` to `b` passes through this smoke
## sphere. Perception (Person 2) and the weapon use this to decide occlusion.
## Uses a cheap point-to-segment distance test so callers can batch it.
func blocks_segment(a: Vector3, b: Vector3) -> bool:
	var center := global_position
	var ab := b - a
	var t := 0.0
	if ab.length_squared() > 0.0001:
		t = clampf((center - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var closest := a + ab * t
	return closest.distance_to(center) <= radius


## True if `point` is inside this smoke sphere (used for the in-smoke fog).
func contains_point(point: Vector3) -> bool:
	return point.distance_to(global_position) <= radius
