extends RefCounted
# PRIVILEGED physical adapter. Never pass this object or its handles into policy.
# Uses only its own actor, static authored destinations, and Person 1's nav API.
const Data = preload("res://perception/plain_data.gd")
var _bot_id: String
var _actor: Node3D
var _navigation: Node3D
var _markers: Dictionary
var _entries: Dictionary
var _clock: int = -1
var _task: Dictionary = {}
var _path: PackedVector3Array = PackedVector3Array()
var _path_index: int = 0
var _feedback: Array = []
var _dispatched: Dictionary = {}
var _progress_distance: float = INF
var _progress_tick: int = -1
var _configured: bool = false
var _fault: String = ""
var _arrival: float
var _stuck_ticks: int

func _init(bot_id: String, actor: Node3D, navigation: Node3D,
		markers: Dictionary, entries: Dictionary, arrival_m: float = 0.25,
		stuck_ticks: int = 120) -> void:
	_bot_id = bot_id
	_actor = actor
	_navigation = navigation
	_arrival = arrival_m
	_stuck_ticks = stuck_ticks
	if not Data.nonempty(bot_id) or not Data.valid(markers) or not Data.valid(entries):
		return
	_markers = markers.duplicate(true)
	_entries = entries.duplicate(true)
	if not is_finite(arrival_m) or arrival_m <= 0.0 or stuck_ticks < 1:
		return
	for id in _markers:
		if not Data.nonempty(id) or not _markers[id] is Dictionary or not Data.keys_exact(_markers[id], ["position", "watch_points"]):
			return
		if not _point(_markers[id].position) or not _markers[id].watch_points is Dictionary:
			return
		for region in _markers[id].watch_points:
			if not Data.nonempty(region) or not _point(_markers[id].watch_points[region]):
				return
	for id in _entries:
		var entry: Variant = _entries[id]
		if not Data.nonempty(id) or not entry is Dictionary or not Data.keys_exact(entry, ["stage_marker_id", "route_marker_ids"]):
			return
		if not entry.stage_marker_id is String or not _markers.has(entry.stage_marker_id) or not entry.route_marker_ids is Array or entry.route_marker_ids.is_empty():
			return
		for marker in entry.route_marker_ids:
			if not marker is String or not _markers.has(marker):
				return
	_configured = true

# Once per physics tick AFTER executor.step and planner.decide. active_command is
# the executor's trusted snapshot. It owns movement even if the planner errors.
# Executor errors freeze ALL movement; a planner error freezes only autonomy.
func step(tick: int, plan: Dictionary, executor_output: Dictionary,
		active_command: Dictionary, inbox: RefCounted) -> Dictionary:
	if tick < 0 or tick <= _clock:
		return _fail("non_monotonic_tick")
	_clock = tick
	if not _configured or not _handles_valid():
		return _fail("invalid_configuration_or_handles")
	if not _actor.is_alive:
		_halt()
		return _status("stopped", "actor_dead")
	if not Data.valid(executor_output) or not executor_output.get("errors") is Array or not executor_output.errors.is_empty() or not executor_output.get("intents") is Array:
		return _fail("executor_error")
	if inbox.owner_id() != _bot_id or inbox.current_tick() != tick:
		return _fail("inbox_not_current_or_foreign")
	# Validate a complete intent batch before any physical side effect.
	for intent in executor_output.intents:
		if not _valid_intent(intent, tick, inbox):
			return _fail("invalid_intent_or_evidence")
	if not Data.valid(active_command):
		return _fail("invalid_active_command")
	var command_id: String = str(active_command.get("message_id", ""))
	if not active_command.is_empty() and command_id.is_empty():
		return _fail("invalid_active_command")
	# A missing/replaced command cannot leave an old physical route running.
	if not _task.is_empty() and not _task.command_id.is_empty() and _task.command_id != command_id:
		_halt()
	if not command_id.is_empty() and not _task.is_empty() and _task.command_id.is_empty():
		_halt()
	for intent in executor_output.intents:
		var key: String = intent.command_id + ":" + intent.op
		if _dispatched.has(key):
			continue
		_dispatched[key] = true
		if intent.op == "stop":
			if not _task.is_empty() and _task.command_id == intent.command_id:
				_halt()
			continue
		if intent.command_id != command_id:
			# A later cancel/supersession in this executor batch wins.
			continue
		if intent.op == "throw_flash":
			# No shared launch/inventory contract yet. Fail honestly, never simulate
			# a throw or claim utility completion from issuing an intent.
			_halt()
			_feedback.append({"command_id": command_id, "phase": "failed"})
			return _status("failed", "utility_adapter_unavailable")
		if not _entries.has(intent.target_id):
			_halt()
			_feedback.append({"command_id": command_id, "phase": "failed"})
			return _status("failed", "unknown_entry")
		var entry: Dictionary = _entries[intent.target_id]
		var route: Array = [entry.stage_marker_id] if intent.op == "stage" else entry.route_marker_ids
		_start(command_id, intent.op, intent.target_id, route, null)
	if not command_id.is_empty():
		if _task.is_empty():
			_stop_actor()
			return _status("command", "waiting_for_command_intent")
		return _advance()
	# Never execute an autonomous plan on the same tick as terminal command
	# stop. This makes cancellation/expiry visibly stop before the next plan.
	if not executor_output.intents.is_empty():
		_halt()
		return _status("stopped", "command_transition")
	if not _valid_plan(plan, tick, inbox):
		return _fail("invalid_plan_or_evidence")
	var decision: Dictionary = plan.decision
	if decision.goal == "stop":
		_halt()
		return _status("stopped", decision.reason)
	if decision.goal == "command":
		return _fail("plan_command_without_executor")
	var marker: String = decision.target_id
	var watch: String = decision.watch_region_id
	# Physical failures latch autonomy until explicit reset after inspection.
	# An accepted command can still override it through the path above.
	if not _fault.is_empty():
		_stop_actor()
		return _status("failed", _fault)
	if _task.is_empty() or _task.target_id != marker or _task.watch_region_id != watch or not _task.command_id.is_empty():
		_start("", "autonomy", marker, [marker], watch)
	return _advance()

func take_feedback() -> Array:
	var result: Array = _feedback.duplicate(true)
	_feedback.clear()
	return result

func reset_fault() -> void:
	# Trusted scene integration calls this only after recovering nav/actor state.
	_fault = ""
	_halt()

func _start(command: String, op: String, target: String, route: Array, watch: Variant) -> void:
	_halt()
	_task = {"command_id": command, "op": op, "target_id": target,
		"route": route.duplicate(), "route_index": 0, "watch_region_id": watch,
		"done": false}
	_progress_distance = INF
	_progress_tick = _clock

func _advance() -> Dictionary:
	if not _navigation.navigation_is_ready:
		return _physical_failure("navigation_not_ready")
	if _task.done:
		_stop_actor()
		_watch()
		return _status("holding", "at_authored_marker")
	var destination: Vector3 = _vec(_markers[_task.route[_task.route_index]].position)
	# query_path snaps endpoints, sometimes onto an unrelated island. Require
	# both returned endpoints near the requested anchors; never walk a partial
	# path and report arrival at an unreachable goal.
	if _path.is_empty():
		_path = _navigation.query_path(_actor.global_position, destination)
		_path_index = 0
		_progress_distance = INF
		if _path.is_empty() or _path[0].distance_to(_actor.global_position) > 0.75 or _path[-1].distance_to(destination) > 0.75:
			return _physical_failure("unreachable_or_off_navigation")
	for point in _path:
		if not point.is_finite():
			return _physical_failure("invalid_navigation_path")
	var previous_index: int = _path_index
	while _path_index < _path.size() and _horizontal(_actor.global_position, _path[_path_index]) <= _arrival:
		_path_index += 1
	if _path_index != previous_index:
		_progress_distance = INF
		_progress_tick = _clock
	if _path_index >= _path.size():
		if _horizontal(_actor.global_position, destination) > _arrival:
			return _physical_failure("partial_navigation_path")
		_path.clear()
		_task.route_index += 1
		_progress_tick = _clock
		_progress_distance = INF
		if _task.route_index < _task.route.size():
			_stop_actor()
			return _status("moving", "next_authored_waypoint")
		_task.done = true
		_stop_actor()
		_watch()
		if not _task.command_id.is_empty():
			_feedback.append({"command_id": _task.command_id,
				"phase": "staged" if _task.op == "stage" else "completed"})
		return _status("holding", "at_authored_marker")
	var remaining: float = _horizontal(_actor.global_position, _path[_path_index])
	if remaining < _progress_distance - 0.1:
		_progress_distance = remaining
		_progress_tick = _clock
	elif _clock - _progress_tick >= _stuck_ticks:
		return _physical_failure("stuck")
	var next: Vector3 = _path[_path_index]
	_actor.move_toward_point(next)
	_face(next)
	return _status("moving", "following_navigation")

func _watch() -> void:
	if _task.watch_region_id is String:
		_face(_vec(_markers[_task.target_id].watch_points[_task.watch_region_id]))

func _face(point: Vector3) -> void:
	var direction: Vector3 = point - _actor.global_position
	if Vector2(direction.x, direction.z).length() > 0.001:
		_actor.rotation.y = atan2(-direction.x, -direction.z)

func _physical_failure(reason: String) -> Dictionary:
	if not _task.is_empty() and not _task.command_id.is_empty():
		_feedback.append({"command_id": _task.command_id, "phase": "failed"})
	else:
		_fault = reason
	_halt()
	return _status("failed", reason)

func _fail(reason: String) -> Dictionary:
	_halt()
	return {"ok": false, "state": "stopped", "reason": reason, "tick": _clock, "bot_id": _bot_id}

func _status(state: String, reason: String) -> Dictionary:
	return {"ok": true, "state": state, "reason": reason, "tick": _clock, "bot_id": _bot_id}

func _halt() -> void:
	_task = {}
	_path.clear()
	_path_index = 0
	_stop_actor()

func _stop_actor() -> void:
	if is_instance_valid(_actor) and _actor.has_method("set_move_dir"):
		_actor.set_move_dir(Vector3.ZERO)

func _handles_valid() -> bool:
	return is_instance_valid(_actor) and _actor.is_inside_tree() and _actor.has_method("set_move_dir") and _actor.has_method("move_toward_point") and _actor.get("is_alive") is bool and _actor.global_position.is_finite() and is_instance_valid(_navigation) and _navigation.has_method("query_path") and _navigation.get("navigation_is_ready") is bool

func _valid_plan(plan: Dictionary, tick: int, inbox: RefCounted) -> bool:
	if not Data.valid(plan) or not Data.equal(plan.get("ok"), true) or not plan.get("decision") is Dictionary:
		return false
	var d: Dictionary = plan.decision
	if not Data.equal(d.get("bot_id"), _bot_id) or not Data.equal(d.get("tick"), tick) or not d.get("reason") is String or not _evidence(d.get("evidence_ids"), tick, inbox):
		return false
	if d.get("goal") in ["stop", "command"]:
		return true
	if d.get("goal") not in ["reposition", "hold", "cover"] or not d.get("target_id") is String or not _markers.has(d.target_id):
		return false
	return d.get("watch_region_id") is String and _markers[d.target_id].watch_points.has(d.watch_region_id)

func _valid_intent(intent: Variant, tick: int, inbox: RefCounted) -> bool:
	if not intent is Dictionary or not Data.keys_exact(intent, ["bot_id", "command_id", "evidence_ids", "op", "target_id", "tick"]):
		return false
	return Data.equal(intent.bot_id, _bot_id) and Data.equal(intent.tick, tick) and Data.nonempty(intent.command_id) and intent.op in ["stage", "start_swing", "throw_flash", "stop"] and intent.target_id is String and _evidence(intent.evidence_ids, tick, inbox)

func _evidence(ids: Variant, tick: int, inbox: RefCounted) -> bool:
	if not ids is Array:
		return false
	for id in ids:
		if not Data.nonempty(id) or not inbox.evidence_available(id, tick):
			return false
	return true

func _point(value: Variant) -> bool:
	return value is Array and value.size() == 3 and value.all(func(n: Variant) -> bool: return (n is int or n is float) and is_finite(float(n)))

func _vec(point: Array) -> Vector3:
	return Vector3(point[0], point[1], point[2])

func _horizontal(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
