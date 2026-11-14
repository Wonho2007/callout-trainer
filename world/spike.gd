extends Node3D
class_name Spike
## Spike (Person 1, shared mechanics).
##
## The spike is already planted at scenario start. It counts down to detonation;
## a defuser holding the defuse action while in range fills a defuse progress.
## Completing the defuse, or the timer reaching zero, ends the round. Durations
## are documented placeholders (brief §6.3), not Valorant values.

signal defused
signal detonated
signal tick(time_left_s: float, defuse_progress: float)

@export var detonation_time_s: float = 45.0
@export var defuse_time_s: float = 7.0
@export var defuse_radius_m: float = 2.0

var time_left: float = 0.0
var defuse_progress: float = 0.0  # 0..1
var is_resolved: bool = false

var _mesh: MeshInstance3D


func _ready() -> void:
	_build_visual()
	reset()


func _build_visual() -> void:
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.3, 0.4)
	_mesh.mesh = box
	_mesh.position.y = 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.2, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.1, 0.1)
	_mesh.material_override = mat
	add_child(_mesh)


## Reset to a freshly planted spike (used on round restart).
func reset() -> void:
	time_left = detonation_time_s
	defuse_progress = 0.0
	is_resolved = false
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if is_resolved:
		return
	time_left = maxf(0.0, time_left - delta)
	tick.emit(time_left, defuse_progress)
	if time_left <= 0.0:
		is_resolved = true
		set_physics_process(false)
		detonated.emit()


## Advance the defuse while a defuser holds the action in range. Pass the
## defuser's world position each physics tick; call stop_defuse() when released.
func defuse_step(defuser_pos: Vector3, delta: float) -> void:
	if is_resolved:
		return
	if defuser_pos.distance_to(global_position) > defuse_radius_m:
		return
	defuse_progress = minf(1.0, defuse_progress + delta / maxf(0.1, defuse_time_s))
	tick.emit(time_left, defuse_progress)
	if defuse_progress >= 1.0:
		is_resolved = true
		set_physics_process(false)
		defused.emit()


## Reset defuse progress when the defuser stops or leaves (defuse must be held).
func stop_defuse() -> void:
	if not is_resolved and defuse_progress > 0.0:
		defuse_progress = 0.0
		tick.emit(time_left, defuse_progress)


## True if a point is within defuse range of the spike.
func in_range(point: Vector3) -> bool:
	return point.distance_to(global_position) <= defuse_radius_m
