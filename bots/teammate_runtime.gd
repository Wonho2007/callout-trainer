extends Node
# PRIVILEGED scene orchestration. This object never enters a policy/model input.
const Data = preload("res://perception/plain_data.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
const Motion = preload("res://bots/motion_controller.gd")
const Gate = preload("res://bots/intent_gate.gd")
signal policy_context_ready(context: Dictionary)
signal decision_recorded(record: Dictionary)
signal comm_result(result: Dictionary)
var _actor: Node3D
var _nav: Node3D
var _belief: RefCounted
var _executor: RefCounted
var _planner: RefCounted
var _motion: RefCounted
var _gate: RefCounted
var _configuration: Dictionary
var _markers: Dictionary
var _entries: Dictionary
var _usable_ids: Dictionary = {}
var _bot_id: String
var _tick: int = -1
var _context_serial: int = 0
var _round_id: int = 0
var _delivery_serial: int = 0
var _status: Dictionary = {}
var _last_plan: Dictionary = {}
var _configured: bool = false

func configure(bot_id: String, actor: Node3D, navigation: Node3D, belief: RefCounted,
		configuration: Dictionary, markers: Dictionary, entries: Dictionary, round_id: int) -> void:
	_bot_id = bot_id
	_actor = actor
	_nav = navigation
	_belief = belief
	_round_id = round_id
	_configuration = configuration.duplicate(true)
	_markers = markers.duplicate(true)
	_entries = entries.duplicate(true)
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	_executor = Executor.new(bot_id, {"entries": entries.keys(), "flashes": [], "regions": configuration.regions, "speakers": ["player"]}, schema, 600)
	_planner = Planner.new(bot_id, configuration)
	_motion = Motion.new(bot_id, actor, navigation, markers, entries)
	var affordances: Dictionary = {}
	for marker in markers:
		affordances[marker] = markers[marker].watch_points.keys()
	_gate = Gate.new(bot_id, affordances)
	_configured = true

# Person 3's trusted voice/interpreter host passes normalized comms.v1 here.
# Fixed radio delivery is an explicit synthetic fixture assumption, not local
# acoustic hearing or a production team-radio/range decision.
func submit_comm(message: Dictionary) -> Dictionary:
	if not _configured or not Data.valid(message) or not Data.integer(message.get("issued_tick")) or message.issued_tick > _tick + 1:
		return {"ok": false, "reason": "invalid_or_future_comm"}
	_delivery_serial += 1
	var event_tick: int = _tick + 1
	return _executor.enqueue({"id": _bot_id + ":round:" + str(_round_id) + ":comm:" + str(_delivery_serial),
		"bot_id": _bot_id, "event_tick": event_tick, "available_tick": event_tick + 18,
		"source": "told", "speaker_id": "player", "content": {"type": "comms", "message": message.duplicate(true)}})

func submit_intent(candidate: Dictionary) -> Dictionary:
	if not _configured:
		return {"ok": false, "reason": "not_ready"}
	return _gate.propose(candidate, _tick)

func current_tick() -> int:
	return _tick

func finish_round(reason: String) -> void:
	# Trusted bootstrap calls for public round completion, not hidden events.
	_configured = false
	_actor.set_move_dir(Vector3.ZERO)
	_status = {"ok": true, "state": "stopped", "reason": reason}

func snapshot() -> Dictionary:
	return {"tick": _tick, "bot_id": _bot_id, "physical": _status.duplicate(true),
		"plan": _last_plan.duplicate(true), "active_command": _executor.active_command_snapshot()}

func _own_state() -> Dictionary:
	var marker_id: String = ""
	var reachable: Array = []
	for id in _markers:
		var coordinates: Array = _markers[id].position
		var at := Vector3(coordinates[0], coordinates[1], coordinates[2])
		var path: PackedVector3Array = _nav.query_path(_actor.global_position, at)
		if not path.is_empty() and path[-1].distance_to(at) <= 0.75 and path[0].distance_to(_actor.global_position) <= 0.75:
			reachable.append(id)
		if _actor.global_position.distance_to(at) < 0.3:
			marker_id = id
	return {"alive": _actor.is_alive, "marker_id": marker_id, "reachable_marker_ids": reachable, "role": "hold", "objective": "none"}

func _physics_process(_delta: float) -> void:
	if not _configured:
		return
	if not _nav.navigation_is_ready:
		_actor.set_move_dir(Vector3.ZERO)
		_status = {"ok": true, "state": "stopped", "reason": "navigation_not_ready"}
		return
	_tick += 1
	var own: Dictionary = _own_state()
	var reachable_entries: Array = []
	for id in _entries:
		var entry: Dictionary = _entries[id]
		var reachable: bool = entry.stage_marker_id in own.reachable_marker_ids
		for waypoint in entry.route_marker_ids:
			reachable = reachable and waypoint in own.reachable_marker_ids
		if reachable:
			reachable_entries.append(id)
	var output: Dictionary = _executor.step(_tick, {"alive": _actor.is_alive,
		"flash_count": 0, "reachable_target_ids": reachable_entries}, _motion.take_feedback())
	for report in output.reports:
		for observation in _executor.inbox.available():
			if observation.id in report.evidence_ids:
				var applied: Dictionary = _belief.apply(observation, _tick)
				if not applied.ok:
					output.errors.append("belief_rejected_accepted_report")
	for result in output.results:
		if result.status != "rejected":
			for id in result.evidence_ids:
				_usable_ids[id] = true
		comm_result.emit(result.duplicate(true))
	var active: Dictionary = _executor.active_command_snapshot()
	var plan: Dictionary = _planner.decide(_tick, _belief.snapshot(), own, _executor.inbox, active)
	var model: Dictionary = _gate.decision(_tick, _executor.inbox)
	var policy: String = "scripted_fallback"
	if not model.is_empty() and active.is_empty() and own.alive:
		plan = {"ok": true, "errors": [], "decision": model, "replanned": true}
		policy = "local_model"
	elif not active.is_empty():
		policy = "accepted_player_command"
	_last_plan = plan.duplicate(true)
	_status = _motion.step(_tick, plan, output, active, _executor.inbox)
	decision_recorded.emit({"tick": _tick, "bot_id": _bot_id, "policy": policy,
		"plan": plan.duplicate(true), "physical": _status.duplicate(true), "model_record": _gate.active_record()})
	# A slow, bounded copied context is available for Person 3's local model.
	# Person 3 must also log its real prompt/raw response; this record cannot
	# establish what an external model actually received on its own.
	if _tick % 30 == 0:
		_context_serial += 1
		var context: Dictionary = {"context_id": _bot_id + ":round:" + str(_round_id) + ":context:" + str(_context_serial),
			"bot_id": _bot_id, "tick": _tick, "expires_tick": _tick + 120,
			"observations": _policy_observations(), "belief": _belief.snapshot(),
			"own_state": own, "active_command": active}
		if _gate.remember(context):
			policy_context_ready.emit(context.duplicate(true))

func _policy_observations() -> Array:
	var usable: Array = []
	for observation in _executor.inbox.available():
		if _usable_ids.has(observation.id):
			usable.append(observation)
	return usable
