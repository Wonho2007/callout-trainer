extends Node3D
class_name Tracer
## Bullet tracer — a purely visual streak from muzzle to impact (Person 1).
##
## The shot is still hitscan: the hit is resolved instantly by the weapon's
## raycast. This only draws a thin line from `from_pos` to `to_pos` and fades it
## out over a short lifetime, for shooter feedback. It changes no gameplay and
## reads no game state. Works for any shooter (player and bots).

@export var lifetime_s: float = 0.05
@export var thickness: float = 0.03

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _age: float = 0.0


## Draw a tracer between two world points, then free self after the lifetime.
func setup(from_pos: Vector3, to_pos: Vector3) -> void:
	var seg := to_pos - from_pos
	var length := seg.length()
	if length < 0.01:
		queue_free()
		return

	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	# A thin long box along local -Z; we orient the node to look down the shot.
	box.size = Vector3(thickness, thickness, length)
	_mesh.mesh = box

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(1.0, 0.9, 0.3)
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.emission_enabled = true
	_mat.emission = Color(1.0, 0.85, 0.3)
	_mesh.material_override = _mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)

	# Position at the midpoint and orient so local -Z points toward the impact.
	global_position = from_pos + seg * 0.5
	var up := Vector3.UP
	# Avoid a degenerate look_at when the shot is near-vertical.
	if absf(seg.normalized().dot(Vector3.UP)) > 0.99:
		up = Vector3.RIGHT
	look_at(to_pos, up)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime_s:
		queue_free()
