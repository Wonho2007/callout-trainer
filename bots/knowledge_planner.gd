extends RefCounted
# Deterministic, bot-local goal selection. No world handles, scene access or LLM.
const Data = preload("res://perception/plain_data.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
var _bot_id: String
var _config: Dictionary = {}
var _markers: Dictionary = {}
var _configured: bool = false
var _clock: int = -1
var _last_plan_tick: int = -1
var _signature: Dictionary = {}
var _last_decision: Dictionary = {}

func _init(bot_id: String, configuration: Dictionary) -> void:
	_bot_id = bot_id
	if Data.nonempty(bot_id) and Data.valid(configuration):
		_config = configuration.duplicate(true)
		_configured = _valid_config()

func decide(tick: int, belief: Dictionary, own_state: Dictionary,
		inbox: Inbox, active_command: Dictionary = {}) -> Dictionary:
	if not _configured:
		return _error("invalid_configuration")
	if tick < 0 or tick < _clock:
		return _error("non_monotonic_tick")
	if inbox.owner_id() != _bot_id or inbox.current_tick() != tick:
		return _error("inbox_not_current_or_foreign")
	if not _valid_state(own_state):
		return _error("invalid_own_state")
	if not _valid_belief(belief, tick, inbox):
		return _error("invalid_belief_or_evidence")
	if not _valid_command(active_command, tick, inbox):
		return _error("invalid_active_command")
	var supports: Dictionary = _positive_supports(belief, inbox)
	var fresh_regions: Array = []
	for region in supports:
		if tick - supports[region] < _config.freshness_ticks:
			fresh_regions.append(region)
	fresh_regions.sort()
	var signature: Dictionary = {"enemies": belief.enemies, "evidence_ids": belief.evidence_ids,
		"state": own_state, "command": active_command, "fresh_regions": fresh_regions}
	var replan: bool = not Data.equal(signature, _signature) or _last_decision.is_empty() or tick - _last_plan_tick >= _config.heartbeat_ticks
	var decision: Dictionary
	if replan:
		decision = _select(tick, belief, own_state, active_command, fresh_regions)
		_signature = signature.duplicate(true)
		_last_decision = decision.duplicate(true)
		_last_plan_tick = tick
	else:
		decision = _last_decision.duplicate(true)
		decision.tick = tick
	_clock = tick
	return {"ok": true, "errors": [], "decision": decision.duplicate(true), "replanned": replan}

func _valid_config() -> bool:
	if not Data.keys_exact(_config, ["regions", "markers", "baseline_marker_id", "baseline_watch_region",
			"threat_threshold", "freshness_ticks", "heartbeat_ticks", "switch_margin"]):
		return false
	if not _texts(_config.regions) or _config.regions.is_empty() or not _config.markers is Array or _config.markers.is_empty():
		return false
	if not _fraction(_config.threat_threshold) or not _fraction(_config.switch_margin):
		return false
	if not Data.integer(_config.freshness_ticks) or _config.freshness_ticks < 1 or not Data.integer(_config.heartbeat_ticks) or _config.heartbeat_ticks < 1:
		return false
	for marker in _config.markers:
		if not marker is Dictionary or not Data.keys_exact(marker, ["id", "watch_regions", "roles", "objectives"]):
			return false
		if not Data.nonempty(marker.id) or _markers.has(marker.id):
			return false
		for key in ["watch_regions", "roles", "objectives"]:
			if not _texts(marker[key]) or marker[key].is_empty():
				return false
		for region in marker.watch_regions:
			if region not in _config.regions:
				return false
		for role in marker.roles:
			if role not in ["hold", "cover"]:
				return false
		for objective in marker.objectives:
			if objective not in ["none", "entry", "defuse"]:
				return false
		_markers[marker.id] = marker.duplicate(true)
	if not Data.nonempty(_config.baseline_marker_id) or not _markers.has(_config.baseline_marker_id):
		return false
	if not Data.nonempty(_config.baseline_watch_region):
		return false
	return _config.baseline_watch_region in _markers[_config.baseline_marker_id].watch_regions

func _valid_state(state: Dictionary) -> bool:
	if not Data.valid(state) or not Data.keys_exact(state, ["alive", "marker_id", "reachable_marker_ids", "role", "objective"]):
		return false
	if not state.alive is bool or not state.marker_id is String or not _texts(state.reachable_marker_ids):
		return false
	if not state.marker_id.is_empty() and not _markers.has(state.marker_id):
		return false
	if not state.role is String or state.role not in ["hold", "cover"] or not state.objective is String or state.objective not in ["none", "entry", "defuse"]:
		return false
	for marker_id in state.reachable_marker_ids:
		if not _markers.has(marker_id):
			return false
	return true

func _valid_belief(belief: Dictionary, tick: int, inbox: Inbox) -> bool:
	if not Data.valid(belief) or not Data.keys_exact(belief, ["bot_id", "tick", "enemies", "evidence_ids"]):
		return false
	if not Data.nonempty(belief.bot_id) or belief.bot_id != _bot_id:
		return false
	if not (Data.integer(belief.tick) or Data.equal(belief.tick, -1)) or belief.tick > tick:
		return false
	if not belief.enemies is Dictionary or belief.enemies.is_empty() or not _texts(belief.evidence_ids):
		return false
	for id in belief.evidence_ids:
		if not inbox.evidence_available(id, int(belief.tick)):
			return false
	for enemy in belief.enemies:
		var distribution: Variant = belief.enemies[enemy]
		if not Data.nonempty(enemy) or not distribution is Dictionary or distribution.size() != _config.regions.size():
			return false
		var total: float = 0.0
		for region in _config.regions:
			if not distribution.has(region) or not _fraction(distribution[region]):
				return false
			total += distribution[region]
		if not is_equal_approx(total, 1.0):
			return false
	return true

func _valid_command(command: Dictionary, tick: int, inbox: Inbox) -> bool:
	if command.is_empty():
		return true
	if not Data.valid(command) or not Data.keys_exact(command, ["message_id", "action", "target_id", "phase", "expires_tick", "evidence_ids"]):
		return false
	for key in ["message_id", "action", "target_id", "phase"]:
		if not Data.nonempty(command[key]):
			return false
	if command.action not in ["swing_together", "throw_flash"] or command.phase not in ["accepted", "ready", "executing"]:
		return false
	if not Data.integer(command.expires_tick) or not _texts(command.evidence_ids) or command.evidence_ids.is_empty():
		return false
	if tick >= command.expires_tick and not (command.action == "throw_flash" and command.phase == "executing"):
		return false
	for id in command.evidence_ids:
		if not inbox.evidence_available(id, tick):
			return false
	for observation in inbox.available():
		if observation.id not in command.evidence_ids or not Data.equal(observation.source, "told"):
			continue
		var message: Variant = observation.content.get("message")
		if not message is Dictionary or not message.get("payload") is Dictionary:
			continue
		if Data.equal(observation.content.get("type"), "comms") and Data.equal(message.get("kind"), "command") and Data.equal(message.get("message_id"), command.message_id) and Data.equal(message.get("recipient_id"), _bot_id) and Data.equal(message.payload.get("action"), command.action) and Data.equal(message.payload.get("target_id"), command.target_id) and Data.equal(message.get("expires_tick"), command.expires_tick):
			return true
	return false

func _positive_supports(belief: Dictionary, inbox: Inbox) -> Dictionary:
	var supports: Dictionary = {}
	for observation in inbox.available():
		if observation.id not in belief.evidence_ids:
			continue
		var content: Dictionary = observation.content
		var region: Variant = null
		if Data.equal(observation.source, "seen") and Data.equal(content.get("type"), "enemy_seen") and content.get("enemy_id") in belief.enemies:
			region = content.get("region_id")
		elif Data.equal(observation.source, "told") and Data.equal(content.get("type"), "comms"):
			var msg: Variant = content.get("message")
			if msg is Dictionary and Data.equal(msg.get("kind"), "report") and msg.get("payload") is Dictionary and Data.equal(msg.payload.get("action"), "report_enemy"):
				region = msg.payload.get("region_id")
		if region is String and region in _config.regions:
			supports[region] = maxi(int(supports.get(region, -1)), int(observation.event_tick))
	return supports

func _select(tick: int, belief: Dictionary, state: Dictionary, command: Dictionary, fresh: Array) -> Dictionary:
	if not state.alive:
		return _decision(tick, "stop", null, null, "actor_dead", [], 0.0)
	if not command.is_empty():
		return _decision(tick, "command", command.target_id, null, "active_player_command",
			command.evidence_ids, 0.0)
	var candidates: Array = []
	var high_mass: bool = false
	var fresh_high_mass: bool = false
	for region in _config.regions:
		var score: float = _region_mass(belief.enemies, region)
		if score < _config.threat_threshold:
			continue
		high_mass = true
		if region not in fresh:
			continue
		fresh_high_mass = true
		for marker_id in state.reachable_marker_ids:
			var marker: Dictionary = _markers[marker_id]
			if _compatible(marker, state) and region in marker.watch_regions:
				candidates.append({"marker_id": marker_id, "region": region, "score": score})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.score != b.score:
			return a.score > b.score
		if (a.marker_id == state.marker_id) != (b.marker_id == state.marker_id):
			return a.marker_id == state.marker_id
		if a.marker_id != b.marker_id:
			return a.marker_id < b.marker_id
		return a.region < b.region)
	if not candidates.is_empty():
		var chosen: Dictionary = candidates[0]
		# Small score fluctuations should not cause coverage oscillation.
		for candidate in candidates:
			if Data.equal(candidate.marker_id, _last_decision.get("target_id")) and Data.equal(candidate.region, _last_decision.get("watch_region_id")) and chosen.score <= candidate.score + _config.switch_margin:
				chosen = candidate
				break
		return _at_marker(tick, chosen.marker_id, chosen.region, state,
			"fresh_belief_coverage", belief.evidence_ids, chosen.score)
	var reason: String = "baseline_no_fresh_threat"
	if high_mass:
		reason = "no_feasible_coverage" if fresh_high_mass else "stale_or_unsubstantiated_belief"
	var fallback: String = _config.baseline_marker_id
	if fallback in state.reachable_marker_ids and _compatible(_markers[fallback], state):
		return _at_marker(tick, fallback, _config.baseline_watch_region, state, reason, belief.evidence_ids, 0.0)
	var possible: Array = state.reachable_marker_ids.duplicate()
	possible.sort()
	if state.marker_id in possible:
		possible.erase(state.marker_id)
		possible.push_front(state.marker_id)
	for marker_id in possible:
		if _compatible(_markers[marker_id], state):
			var watches: Array = _markers[marker_id].watch_regions.duplicate()
			watches.sort()
			return _at_marker(tick, marker_id, watches[0], state, reason, belief.evidence_ids, 0.0)
	return _decision(tick, "stop", null, null, "no_reachable_goal", belief.evidence_ids, 0.0)

func _at_marker(tick: int, marker_id: String, region: String, state: Dictionary,
		reason: String, evidence: Array, score: float) -> Dictionary:
	var goal: String = "reposition"
	if marker_id == state.marker_id:
		goal = "cover" if state.role == "cover" else "hold"
	return _decision(tick, goal, marker_id, region, reason, evidence, score)

func _decision(tick: int, goal: String, target: Variant, region: Variant,
		reason: String, evidence: Array, score: float) -> Dictionary:
	return {"tick": tick, "bot_id": _bot_id, "goal": goal, "target_id": target,
		"watch_region_id": region, "reason": reason, "evidence_ids": evidence.duplicate(),
		"score": score}

func _region_mass(enemies: Dictionary, region: String) -> float:
	var ids: Array = enemies.keys()
	ids.sort()
	var total: float = 0.0
	for enemy in ids:
		total += enemies[enemy][region]
	# Average marginal mass, not P(any enemy here); no independence assumption.
	return total / ids.size()

func _compatible(marker: Dictionary, state: Dictionary) -> bool:
	return state.role in marker.roles and state.objective in marker.objectives

func _texts(value: Variant) -> bool:
	if not value is Array:
		return false
	var seen: Dictionary = {}
	for item in value:
		if not Data.nonempty(item) or seen.has(item):
			return false
		seen[item] = true
	return true

func _fraction(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0.0 and value <= 1.0

func _error(reason: String) -> Dictionary:
	return {"ok": false, "errors": [reason], "decision": {}, "replanned": false}
