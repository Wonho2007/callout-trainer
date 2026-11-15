extends RefCounted
# Pure validation of Person 3's proposed model-goal seam. No model calls/world IO.
const Data = preload("res://perception/plain_data.gd")
var _bot_id: String
var _markers: Dictionary
var _contexts: Dictionary = {}
var _proposal: Dictionary = {}
var _used_ids: Dictionary = {}

func _init(bot_id: String, markers: Dictionary) -> void:
	_bot_id = bot_id
	_markers = markers.duplicate(true) if Data.valid(markers) else {}

# The trusted runtime creates this context from released inbox values ONLY.
func remember(context: Dictionary) -> bool:
	if not Data.valid(context) or not Data.keys_exact(context, ["context_id", "bot_id", "tick", "expires_tick", "observations", "belief", "own_state", "active_command"]):
		return false
	if not Data.nonempty(context.context_id) or not Data.equal(context.bot_id, _bot_id) or not Data.integer(context.tick) or not Data.integer(context.expires_tick) or context.expires_tick <= context.tick or not context.observations is Array:
		return false
	for observation in context.observations:
		if not observation is Dictionary or not Data.equal(observation.get("bot_id"), _bot_id) or not Data.nonempty(observation.get("id")) or not Data.integer(observation.get("available_tick")) or observation.available_tick > context.tick:
			return false
	if _contexts.has(context.context_id):
		return false
	_contexts[context.context_id] = context.duplicate(true)
	while _contexts.size() > 8:
		_contexts.erase(_contexts.keys()[0])
	return true

func propose(candidate: Dictionary, tick: int) -> Dictionary:
	if not Data.valid(candidate) or not Data.keys_exact(candidate, ["context_id", "decision_id", "bot_id", "goal", "target_id", "watch_region_id", "evidence_ids"]):
		return _reject("invalid_goal_shape")
	if not Data.equal(candidate.bot_id, _bot_id) or not Data.nonempty(candidate.decision_id) or not candidate.context_id is String or not _contexts.has(candidate.context_id):
		return _reject("unknown_context_or_bot")
	if _used_ids.has(candidate.decision_id):
		return _reject("duplicate_decision")
	if not candidate.goal is String or candidate.goal not in ["hold", "cover", "reposition", "stop"] or not candidate.evidence_ids is Array:
		return _reject("unsupported_goal")
	if candidate.goal == "stop":
		if candidate.target_id != null or candidate.watch_region_id != null:
			return _reject("stop_has_target")
	elif not candidate.target_id is String or not _markers.has(candidate.target_id) or not candidate.watch_region_id is String or candidate.watch_region_id not in _markers[candidate.target_id]:
		return _reject("unknown_authored_target")
	var context: Dictionary = _contexts[candidate.context_id]
	if tick < context.tick or tick >= context.expires_tick:
		return _reject("expired_or_future_context")
	if candidate.goal != "stop" and candidate.target_id not in context.own_state.get("reachable_marker_ids", []):
		return _reject("target_unreachable_in_context")
	var available: Array = []
	for observation in context.observations:
		available.append(observation.id)
	var seen: Array = []
	for id in candidate.evidence_ids:
		if not Data.nonempty(id) or id not in available or id in seen:
			return _reject("evidence_outside_recorded_context")
		seen.append(id)
	_used_ids[candidate.decision_id] = true
	_proposal = candidate.duplicate(true)
	return {"ok": true, "reason": "validated_goal"}

func decision(tick: int, inbox: RefCounted) -> Dictionary:
	if _proposal.is_empty() or not _contexts.has(_proposal.context_id):
		return {}
	var context: Dictionary = _contexts[_proposal.context_id]
	if tick < context.tick or tick >= context.expires_tick:
		_proposal = {}
		return {}
	for id in _proposal.evidence_ids:
		if not inbox.evidence_available(id, int(context.tick)):
			_proposal = {}
			return {}
	return {"tick": tick, "bot_id": _bot_id, "goal": _proposal.goal,
		"target_id": _proposal.target_id, "watch_region_id": _proposal.watch_region_id,
		"reason": "local_model_goal", "evidence_ids": _proposal.evidence_ids.duplicate(), "score": 0.0}

func active_record() -> Dictionary:
	if _proposal.is_empty():
		return {}
	return {"intent": _proposal.duplicate(true), "context": _contexts.get(_proposal.context_id, {}).duplicate(true)}

func _reject(reason: String) -> Dictionary:
	# Invalid new model output drops model control, allowing the fallback now.
	_proposal = {}
	return {"ok": false, "reason": reason}
