extends Node3D
signal sampled(result: Dictionary)
var _request: Dictionary = {}

func sample(sensor: RefCounted, tick: int, observer: Dictionary, targets: Array,
		sounds: Array = [], navigation_map: RID = RID()) -> Dictionary:
	_request = {"sensor": sensor, "tick": tick, "observer": observer,
		"targets": targets, "sounds": sounds, "navigation_map": navigation_map}
	var result: Dictionary = await sampled
	return result

func _physics_process(_delta: float) -> void:
	if _request.is_empty():
		return
	var request: Dictionary = _request
	_request = {}
	var result: Dictionary = request.sensor.sample(request.tick, request.observer, request.targets,
		request.sounds, get_world_3d().direct_space_state, request.navigation_map)
	sampled.emit(result)
