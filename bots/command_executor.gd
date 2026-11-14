extends RefCounted
# Pure policy state machine: no actor Nodes, world handles or callbacks.
const Data = preload("res://perception/plain_data.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
const Validator = preload("res://validation/comms_validator.gd")

var inbox: RefCounted
var _validator: RefCounted
var _bot_id: String
var _catalog: Dictionary
var _clock: int = -1
var _active: Dictionary = {}
var _messages: Dictionary = {}
var _last_results: Dictionary = {}
var _serial: int = 0
var _max_execution_ticks: int
var _output: Dictionary = {}

func _init(bot_id: String, catalog: Dictionary, schema: Dictionary, max_execution_ticks: int = 120) -> void:
	_bot_id = bot_id
	_catalog = catalog.duplicate(true)
	_validator = Validator.new(schema)
	inbox = Inbox.new(bot_id)
	_max_execution_ticks = maxi(1, max_execution_ticks)

func enqueue(observation: Dictionary) -> Dictionary:
	return inbox.enqueue(observation)

func active_command_id() -> String:
	return str(_active.get("message", {}).get("message_id", ""))

func step(tick: int, own_state: Dictionary, feedback: Array = []) -> Dictionary:
	_output = {"results": [], "intents": [], "reports": [], "errors": []}
	if tick <= _clock or tick < 0:
		_output.errors.append("non_monotonic_tick")
		return _output.duplicate(true)
	if not _valid_state(own_state):
		_output.errors.append("invalid_actor_state")
		return _output.duplicate(true)
	if not _valid_feedback(feedback):
		_output.errors.append("invalid_feedback")
		return _output.duplicate(true)
	_clock = tick
	var due: Array = inbox.release(tick)
	# Expiry/death take priority over an arriving cue or stale completion.
	if not _active.is_empty():
		if not own_state.alive:
			_finish("failed", "actor_dead")
		elif _active.phase == "executing" and tick - _active.started_tick >= _max_execution_ticks:
			_finish("failed", "execution_failed")
		elif not _active.committed and tick >= _active.message.expires_tick:
			_finish("expired", "expired")
	for item in feedback:
		_handle_feedback(item, own_state)
	for observation in due:
		var content_type: Variant = observation.content.get("type")
		if not content_type is String:
			continue
		if content_type == "comms":
			_receive(observation, own_state)
		elif content_type == "player_entry":
			_follow(observation, own_state)
	return _output.duplicate(true)

func _valid_state(state: Dictionary) -> bool:
	if not Data.valid(state) or not Data.keys_exact(state, ["alive", "flash_count", "reachable_target_ids"]):
		return false
	if not state.alive is bool or not Data.integer(state.flash_count) or not state.reachable_target_ids is Array:
		return false
	for target in state.reachable_target_ids:
		if not Data.nonempty(target):
			return false
	return true

func _valid_feedback(feedback: Array) -> bool:
	if not Data.valid(feedback):
		return false
	var seen: Dictionary = {}
	for item in feedback:
		if not item is Dictionary or not Data.keys_exact(item, ["command_id", "phase"]):
			return false
		if not item.phase is String or item.phase not in ["staged", "completed", "failed"] or not Data.nonempty(item.command_id):
			return false
		if seen.has(item.command_id):
			return false
		seen[item.command_id] = true
	return true

func _receive(observation: Dictionary, state: Dictionary) -> void:
	var raw: Variant = observation.content.get("message")
	var msg: Dictionary = raw if raw is Dictionary else {}
	var id: String = str(msg.get("message_id", "invalid:" + observation.id))
	var evidence: Array = [observation.id]
	if not _validator.valid(msg) or observation.source != "told" or msg.get("recipient_id") != _bot_id or msg.get("speaker_id") != observation.speaker_id:
		_result(id, "rejected", "invalid_message", evidence, false)
		return
	if msg.issued_tick > observation.event_tick or msg.expires_tick <= msg.issued_tick:
		_result(id, "rejected", "invalid_message", evidence, false)
		return
	if _messages.has(id):
		if Data.equal(_messages[id], msg):
			_output.results.append(_last_results[id].duplicate(true))
		else:
			_result(id, "rejected", "invalid_message", evidence, false)
		return
	_messages[id] = msg.duplicate(true)
	if msg.speaker_id not in _catalog.get("speakers", []):
		_result(id, "rejected", "invalid_message", evidence)
		return
	if _clock >= msg.expires_tick:
		_result(id, "rejected", "expired", evidence)
		return
	if not state.alive:
		_result(id, "rejected", "actor_dead", evidence)
		return
	match msg.kind:
		"report":
			if msg.payload.region_id not in _catalog.get("regions", []):
				_result(id, "rejected", "unknown_target", evidence)
				return
			_output.reports.append({"message_id": id, "speaker_id": msg.speaker_id,
				"payload": msg.payload.duplicate(true), "tick": _clock, "evidence_ids": evidence.duplicate()})
			_result(id, "completed", "ok", evidence)
		"command":
			_accept(msg, state, evidence)
		"cue", "cancel":
			_reference(msg, state, evidence)

func _feasibility(msg: Dictionary, state: Dictionary) -> String:
	var group: String = "entries" if msg.payload.action == "swing_together" else "flashes"
	if msg.payload.target_id not in _catalog.get(group, []):
		return "unknown_target"
	if msg.payload.target_id not in state.reachable_target_ids:
		return "unreachable"
	if msg.payload.action == "throw_flash" and state.flash_count < 1:
		return "no_utility"
	return ""

func _accept(msg: Dictionary, state: Dictionary, evidence: Array) -> void:
	var failure: String = _feasibility(msg, state)
	if not failure.is_empty():
		_result(msg.message_id, "rejected", failure, evidence)
		return
	if not _active.is_empty():
		if _active.committed:
			_result(msg.message_id, "rejected", "busy_committed", evidence)
			return
		_active.evidence_ids.append_array(evidence)
		_finish("cancelled", "superseded")
	_active = {"message": msg.duplicate(true), "phase": "accepted", "committed": false,
		"started_tick": -1, "ready_tick": -1, "evidence_ids": evidence.duplicate()}
	_result(msg.message_id, "accepted", "ok", evidence)
	if msg.payload.action == "throw_flash" and msg.payload.timing.mode == "now":
		_start(state)
	else:
		_intent("stage")

func _reference(msg: Dictionary, state: Dictionary, evidence: Array) -> void:
	if _active.is_empty() or msg.payload.command_id != _active.message.message_id or msg.speaker_id != _active.message.speaker_id:
		_result(msg.message_id, "rejected", "unknown_command", evidence)
		return
	if msg.kind == "cancel":
		if _active.committed:
			_result(msg.message_id, "rejected", "busy_committed", evidence)
			return
		_active.evidence_ids.append_array(evidence)
		_finish("cancelled", "cancelled_by_player")
		_result(msg.message_id, "completed", "ok", evidence)
		return
	if _active.phase != "ready" or _active.message.payload.timing.mode != "on_cue":
		_result(msg.message_id, "rejected", "not_ready", evidence)
		return
	# No retroactive cue recorded before the bot became ready.
	if msg.issued_tick < _active.ready_tick:
		_result(msg.message_id, "rejected", "not_ready", evidence)
		return
	_active.evidence_ids.append_array(evidence)
	var failure: String = _start(state)
	_result(msg.message_id, "completed" if failure.is_empty() else "rejected", "ok" if failure.is_empty() else failure, evidence)

func _handle_feedback(raw: Variant, state: Dictionary) -> void:
	if not raw is Dictionary or not Data.keys_exact(raw, ["command_id", "phase"]):
		_output.errors.append("invalid_feedback")
		return
	if raw.phase not in ["staged", "completed", "failed"] or not Data.nonempty(raw.command_id):
		_output.errors.append("invalid_feedback")
		return
	if _active.is_empty() or raw.command_id != _active.message.message_id:
		return
	match raw.phase:
		"staged":
			if _active.phase != "accepted":
				return
			_active.phase = "ready"
			_active.ready_tick = _clock
			_result(_active.message.message_id, "ready", "ok", _active.evidence_ids)
			if _active.message.payload.timing.mode == "now":
				_start(state)
		"completed":
			if _active.phase == "executing" and _clock > _active.started_tick:
				_finish("completed", "ok")
		"failed":
			_finish("failed", "execution_failed")

func _follow(observation: Dictionary, state: Dictionary) -> void:
	if _active.is_empty() or _active.phase != "ready" or _active.message.payload.timing.mode != "follow_player":
		return
	if observation.source not in ["seen", "heard"]:
		return
	var content: Dictionary = observation.content
	if not Data.keys_exact(content, ["type", "actor_id", "entry_id"]):
		return
	if not Data.nonempty(content.actor_id) or not Data.nonempty(content.entry_id):
		return
	if content.actor_id != _active.message.speaker_id or content.entry_id != _active.message.payload.target_id or observation.event_tick < _active.ready_tick:
		return
	_active.evidence_ids.append(observation.id)
	_start(state)

func _start(state: Dictionary) -> String:
	var failure: String = _feasibility(_active.message, state)
	if not failure.is_empty():
		_finish("failed", failure)
		return failure
	_active.phase = "executing"
	_active.started_tick = _clock
	var op: String = "start_swing"
	if _active.message.payload.action == "throw_flash":
		op = "throw_flash"
		# Dispatch is the commit boundary: no cancellation/refund after release.
		_active.committed = true
	_result(_active.message.message_id, "executing", "ok", _active.evidence_ids)
	_intent(op)
	return ""

func _finish(status: String, reason: String) -> void:
	if _active.is_empty():
		return
	if not _active.committed and status != "completed":
		_intent("stop")
	_result(_active.message.message_id, status, reason, _active.evidence_ids)
	_active = {}

func _intent(op: String) -> void:
	_output.intents.append({"command_id": _active.message.message_id, "bot_id": _bot_id,
		"tick": _clock, "op": op, "target_id": _active.message.payload.target_id,
		"evidence_ids": _active.evidence_ids.duplicate()})

func _result(id: String, status: String, reason: String, evidence: Array, cache: bool = true) -> void:
	for evidence_id in evidence:
		if not inbox.evidence_available(evidence_id, _clock):
			_output.errors.append("invalid_evidence")
			return
	_serial += 1
	var result: Dictionary = {"schema_version": "comms.v1", "result_id": _bot_id + ":" + str(_serial),
		"message_id": id, "bot_id": _bot_id, "tick": _clock, "status": status,
		"reason_code": reason, "evidence_ids": evidence.duplicate()}
	_output.results.append(result)
	if cache:
		_last_results[id] = result.duplicate(true)
