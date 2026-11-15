extends Node3D
class_name BlindWave
## Blind wave — a directional blind that travels forward and passes through
## walls (Person 1, shared mechanics).
##
## Built from the generic `blind` primitive. Unlike the thrown flash, this is a
## wave sent in a straight line from the caster; when it reaches its travel
## distance it detonates and blinds actors facing toward it, and its blind check
## IGNORES line-of-sight geometry (it goes through walls). It still requires the
## viewer to be facing roughly toward the wave, so it is directional, not
## omniscient. This is an original ability, not a replica of any agent kit.
##
## Fairness: like the flash, this node only computes a per-viewer blind amount
## from geometry/facing; it does not reach into bot policy. Person 2 applies it
## to bots; Person 1 applies it to the player. Values are documented placeholders.

signal detonated(source_position: Vector3)
signal expired

var wave_speed: float = 14.0
var travel_m: float = 18.0
var max_blind_s: float = 1.6
var min_blind_s: float = 0.4
var radius_m: float = 6.0
var through_walls: bool = true

var is_active: bool = false
var _dir: Vector3 = Vector3.FORWARD
var _travelled: float = 0.0
var _mesh: MeshInstance3D


func setup(ability: Dictionary) -> void:
	wave_speed = float(ability.get("wave_speed", wave_speed))
	travel_m = float(ability.get("travel_m", travel_m))
	max_blind_s = float(ability.get("max_blind_s", max_blind_s))
	min_blind_s = float(ability.get("min_blind_s", min_blind_s))
	radius_m = float(ability.get("radius_m", radius_m))
	through_walls = bool(ability.get("through_walls", through_walls))


## Launch the wave from `from` travelling along horizontal `direction`.
func launch(from: Vector3, direction: Vector3) -> void:
	global_position = from
	var d := direction
	d.y = 0.0
	if d.length() < 0.001:
		d = Vector3.FORWARD
	_dir = d.normalized()


func _ready() -> void:
	_build_visual()


func _build_visual() -> void:
	# A translucent disc that reads as the travelling wavefront.
	_mesh = MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.6
	mesh.height = 1.2
	_mesh.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.85, 1.0, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.8, 1.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mesh.material_override = mat
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	var step := wave_speed * delta
	global_position += _dir * step
	_travelled += step
	if _travelled >= travel_m:
		_detonate()


func _detonate() -> void:
	is_active = true
	set_physics_process(false)
	if _mesh:
		_mesh.visible = false
	detonated.emit(global_position)
	# Hold briefly so viewers can sample the blind, then expire.
	await get_tree().create_timer(0.1).timeout
	is_active = false
	expired.emit()
	queue_free()


## Blind duration for a viewer. Blinds if the viewer is within radius and facing
## toward the wave's detonation point. If `through_walls` is true, geometry
## occlusion is ignored (that is this ability's defining trait); otherwise the
## caller's `has_los` is honoured like the flash.
func blind_duration_for(viewer_pos: Vector3, viewer_forward: Vector3, has_los: bool) -> float:
	if not through_walls and not has_los:
		return 0.0
	var to_source := global_position - viewer_pos
	var dist := to_source.length()
	if dist > radius_m or dist < 0.001:
		return 0.0
	var dir := to_source / dist
	var facing := viewer_forward.normalized().dot(dir)
	if facing <= 0.0:
		return 0.0
	var range_factor := 1.0 - (dist / radius_m)
	var strength := facing * range_factor
	return lerpf(min_blind_s, max_blind_s, clampf(strength, 0.0, 1.0))
