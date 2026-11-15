extends Node3D
class_name ReconOutline
## A decaying through-wall marker for a scan-orb contact (Person 1).
##
## Spawned at an enemy position the scan orb actually SAW at scan time. It
## renders on top of geometry (visible through walls) so the player gets a
## last-known highlight, and fades out over the reveal window. It is a static
## snapshot of fair information (not live tracking) and is PLAYER-ONLY visual:
## nothing here is read by bot policy. Original ability, documented placeholders.

var reveal_duration_s: float = 4.0

var _mat: StandardMaterial3D
var _age: float = 0.0


## Place at a scanned position and fade over `duration`. Call after add_child.
func setup(at: Vector3, duration: float) -> void:
	reveal_duration_s = maxf(0.1, duration)
	global_position = at + Vector3(0, 1.0, 0)  # torso height

	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 2.0
	mesh_instance.mesh = capsule

	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.95, 0.85, 0.2, 0.7)
	_mat.emission_enabled = true
	_mat.emission = Color(0.95, 0.8, 0.1)
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Render on top of geometry so the outline shows through walls.
	_mat.no_depth_test = true
	_mat.render_priority = 10
	mesh_instance.material_override = _mat
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)


func _process(delta: float) -> void:
	_age += delta
	if _age >= reveal_duration_s:
		queue_free()
		return
	if _mat:
		# Fade the outline out over its lifetime.
		_mat.albedo_color.a = (1.0 - _age / reveal_duration_s) * 0.7
