extends RefCounted
# Authored adaptation policy: copied delayed evidence + own state only.
var _bot_id: String
var _baseline: String
var _branch_until: int = -1
var _branch_evidence: Array = []

func _init(bot_id: String, baseline: String) -> void:
	_bot_id = bot_id
	_baseline = baseline

func decide(tick: int, observations: Array, own: Dictionary) -> Dictionary:
	for observation in observations:
		if observation.get("bot_id") != _bot_id or int(observation.get("available_tick", tick + 1)) > tick:
			continue
		var content: Dictionary = observation.get("content", {})
		if _branch_until < 0 and observation.get("source") == "seen" and tick - int(observation.get("event_tick", -999)) <= 180 and content.get("type") == "enemy_seen" and content.get("region_id") == "b_heaven":
			_branch_until = tick + 180
			_branch_evidence = [observation.id]
	var branch: bool = tick < _branch_until
	var target: String = "a_link" if branch else _baseline
	var reason: String = "observed_heaven_flank_adaptation" if branch else "authored_retake_baseline"
	var goal: String = "hold" if own.get("marker_id") == target else "reposition"
	if not own.get("alive", false) or target not in own.get("reachable_marker_ids", []):
		return {"tick": tick, "bot_id": _bot_id, "goal": "stop", "target_id": null, "watch_region_id": null,
			"evidence_ids": [], "reason": "retake_no_reachable_goal", "score": 0.0}
	return {"tick": tick, "bot_id": _bot_id, "goal": goal, "target_id": target, "watch_region_id": "b_pit",
		"evidence_ids": _branch_evidence.duplicate() if branch else [], "reason": reason, "score": 0.0}
