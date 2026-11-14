extends RefCounted
# One instance per bot. Only copied bot-local observations enter this module.
const Values = preload("res://belief/plain_values.gd")
const Reports = preload("res://comms/report_adapter.gd")
var _bot_id: String
var _regions: Array
var _enemies: Array
var _probabilities: Dictionary = {}
var _observations: Dictionary = {}
var _messages: Dictionary = {}
var _evidence: Array = []
var _tick: int = -1

func _init(bot_id: String, region_ids: Array, enemy_ids: Array) -> void:
	assert(Values.text(bot_id) and not region_ids.is_empty() and not enemy_ids.is_empty())
	assert(Values.valid(region_ids) and Values.valid(enemy_ids))
	_bot_id = bot_id
	_regions = region_ids.duplicate()
	_enemies = enemy_ids.duplicate()
	for region in _regions:
		assert(Values.text(region) and _regions.count(region) == 1)
	for enemy in _enemies:
		assert(Values.text(enemy) and _enemies.count(enemy) == 1)
		var prior: Dictionary = {}
		for region in _regions:
			prior[region] = 1.0 / _regions.size()
		_probabilities[enemy] = prior

func snapshot() -> Dictionary:
	# `trust` is retained as an always-empty dict for backward compatibility with
	# Person 2's planner contract (keys_exact requires the key). Trust was removed
	# as a mechanism (DECISIONS.md 2026-11-14); nothing populates it. Person 2 can
	# drop the field from their validator in a coordinated change.
	return {"bot_id": _bot_id, "tick": _tick, "enemies": _probabilities.duplicate(true),
		"trust": {}, "evidence_ids": _evidence.duplicate()}

# Caller releases observations using Person 2's inbox. Reject future/foreign values.
# No wall clock or world queries. Prediction is an explicit separate step.
func apply(observation: Dictionary, tick: int) -> Dictionary:
	if tick < _tick or not _valid_observation(observation, tick):
		return {"ok": false, "reason": "invalid_or_unavailable_observation"}
	if _observations.has(observation.id):
		return {"ok": _observations[observation.id] == observation, "reason": "duplicate_observation"}
	var content: Dictionary = observation.content
	var reason: String = "unsupported_content"
	if observation.source == "told" and content.get("type") == "comms":
		reason = _report(observation, tick)
	elif observation.source == "seen" and content.get("type") == "enemy_seen":
		reason = _seen(observation, tick)
	elif observation.source == "seen" and content.get("type") == "region_clear":
		reason = _clear(observation, tick)
	if reason != "ok" and reason != "duplicate_message":
		return {"ok": false, "reason": reason}
	_tick = tick
	_observations[observation.id] = observation.duplicate(true)
	_evidence.append(observation.id)
	return {"ok": true, "reason": reason}

func _valid_observation(observation: Dictionary, tick: int) -> bool:
	if not Values.valid(observation) or not Values.keys(observation,
			["id", "bot_id", "event_tick", "available_tick", "source", "speaker_id", "content"]):
		return false
	return Values.text(observation.id) and observation.bot_id == _bot_id and Values.integer(observation.event_tick) and Values.integer(observation.available_tick) and observation.event_tick <= observation.available_tick and observation.available_tick <= tick and Values.text(observation.speaker_id) and observation.content is Dictionary

func _report(observation: Dictionary, tick: int) -> String:
	if not Values.keys(observation.content, ["type", "message"]) or not observation.content.message is Dictionary:
		return "invalid_message"
	var message: Dictionary = observation.content.message
	if not Reports.valid_report(message) or message.recipient_id != _bot_id or message.speaker_id != observation.speaker_id or message.issued_tick > observation.event_tick:
		return "invalid_message"
	if _messages.has(message.message_id):
		return "duplicate_message" if _messages[message.message_id] == message else "conflicting_message_id"
	if tick >= message.expires_tick:
		return "expired"
	var region: String = message.payload.region_id
	if region not in _regions:
		return "unknown_region"
	# No per-speaker trust: the bot believes the call and acts on it. The player's
	# own hedge is the only strength knob; a wrong call commits the bot and the
	# consequence is a bad in-round outcome, not a hidden trust penalty.
	var strength: float = {"sure": 0.9, "think": 0.7, "unsure": 0.4}[message.payload.hedge]
	# No identity in report_enemy: exchangeable-slot approximation, not a sighting
	# of every enemy. Count is retained for grading; no slot identity is invented.
	for enemy in _enemies:
		var likelihood: Dictionary = {}
		for candidate in _regions:
			likelihood[candidate] = (strength if candidate == region else 0.0) + (1.0 - strength) / _regions.size()
		_update(enemy, likelihood)
	_messages[message.message_id] = message.duplicate(true)
	return "ok"

func _seen(observation: Dictionary, tick: int) -> String:
	var content: Dictionary = observation.content
	if not Values.keys(content, ["type", "enemy_id", "region_id"]) or content.enemy_id not in _enemies or content.region_id not in _regions:
		return "invalid_sighting"
	var likelihood: Dictionary = {}
	for region in _regions:
		likelihood[region] = 0.99 if region == content.region_id else 0.01 / max(1, _regions.size() - 1)
	_update(content.enemy_id, likelihood)
	return "ok"

func _clear(observation: Dictionary, tick: int) -> String:
	var content: Dictionary = observation.content
	# Perception, not the belief model, must establish complete dynamic coverage.
	if not Values.keys(content, ["type", "region_id", "coverage"]) or content.region_id not in _regions or content.coverage != "complete":
		return "incomplete_coverage"
	var likelihood: Dictionary = {}
	for region in _regions:
		likelihood[region] = 0.1 if region == content.region_id else 1.0
	for enemy in _enemies:
		_update(enemy, likelihood)
	return "ok"

func _update(enemy: String, likelihood: Dictionary) -> void:
	var total: float = 0.0
	for region in _regions:
		_probabilities[enemy][region] *= likelihood[region]
		total += _probabilities[enemy][region]
	for region in _regions:
		_probabilities[enemy][region] /= total

# Explicit one-step transition matrix from the static map adapter. Do not infer
# travel rates from elapsed ticks; caller supplies the configured movement step.
func predict(tick: int, transition: Dictionary) -> bool:
	if tick <= _tick or not Values.valid(transition) or transition.size() != _regions.size():
		return false
	for origin in _regions:
		if not transition.get(origin) is Dictionary or transition[origin].size() != _regions.size():
			return false
		var total: float = 0.0
		for destination in _regions:
			var weight: Variant = transition[origin].get(destination)
			if not (weight is float or weight is int) or weight < 0:
				return false
			total += weight
		if not is_equal_approx(total, 1.0):
			return false
	for enemy in _enemies:
		var next: Dictionary = {}
		var mass: float = 0.0
		for destination in _regions:
			next[destination] = 0.0
			for origin in _regions:
				next[destination] += _probabilities[enemy][origin] * transition[origin][destination]
			mass += next[destination]
		# Tolerated floating point row-sum noise must not compound over a run.
		for destination in _regions:
			next[destination] /= mass
		_probabilities[enemy] = next
	_tick = tick
	return true
