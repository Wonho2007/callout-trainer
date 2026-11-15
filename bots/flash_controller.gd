extends RefCounted
# PRIVILEGED physical release adapter. Static authored throws and own inventory
# only; never receives opponent references or model-supplied coordinates.
const Data = preload("res://perception/plain_data.gd")
var _actor: Node3D
var _utility: Node3D
var _targets: Dictionary = {}
var _markers: Dictionary = {}
var _remaining: int = 0
var _released: Dictionary = {}

func _init(actor: Node3D, utility: Node3D, targets: Dictionary, markers: Dictionary, charges: int) -> void:
	_actor = actor
	_utility = utility
	if not Data.valid(targets) or not Data.valid(markers) or charges < 0:
		return
	for id in targets:
		var target: Variant = targets[id]
		if not Data.nonempty(id) or not target is Dictionary or not Data.keys_exact(target, ["stage_marker_id", "velocity"]):
			return
		if not target.stage_marker_id is String or not markers.has(target.stage_marker_id):
			return
		if not target.velocity is Array or target.velocity.size() != 3:
			return
		for value in target.velocity:
			if not (value is float or value is int) or not is_finite(float(value)):
				return
	_targets = targets.duplicate(true)
	_markers = markers.duplicate(true)
	_remaining = charges

func targets() -> Dictionary:
	return _targets.duplicate(true)

func remaining() -> int:
	return _remaining

func launch(command_id: String, target_id: String) -> Dictionary:
	if _released.has(command_id):
		return _released[command_id].duplicate(true)
	var reason: String = ""
	if not is_instance_valid(_actor) or not _actor.is_alive:
		reason = "actor_dead"
	elif not _targets.has(target_id):
		reason = "unknown_flash_target"
	elif _remaining < 1:
		reason = "no_utility"
	elif not is_instance_valid(_utility) or not _utility.has_method("throw_flash"):
		reason = "utility_adapter_unavailable"
	else:
		var p: Array = _markers[_targets[target_id].stage_marker_id].position
		if _actor.global_position.distance_to(Vector3(p[0], p[1], p[2])) > 0.75:
			reason = "outside_authored_launch_position"
	if not reason.is_empty():
		_released[command_id] = {"ok": false, "reason": reason}
		return _released[command_id].duplicate(true)
	# Reserve before the synchronous shared deployed signal; even a reentrant
	# callback cannot release twice. Failed physical spawn refunds the charge.
	_remaining -= 1
	_released[command_id] = {"ok": false, "reason": "launch_in_progress"}
	var v: Array = _targets[target_id].velocity
	var effect: Node3D = _utility.throw_flash(_actor.global_position + Vector3.UP * 1.6, Vector3(v[0], v[1], v[2]))
	if not is_instance_valid(effect):
		_remaining += 1
		_released[command_id] = {"ok": false, "reason": "physical_launch_failed"}
	else:
		_released[command_id] = {"ok": true, "reason": "projectile_released"}
	return _released[command_id].duplicate(true)
