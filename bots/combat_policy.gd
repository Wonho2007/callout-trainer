extends RefCounted
# Pure copied-information policy. No actors, scene queries or physics handles.
const Data = preload("res://perception/plain_data.gd")
var _bot_id: String
var _fresh_ticks: int

func _init(bot_id: String, freshness_ticks: int = 30) -> void:
	_bot_id = bot_id
	_fresh_ticks = clampi(freshness_ticks, 1, 30)

func decide(tick: int, observations: Array, own: Dictionary) -> Dictionary:
	if not Data.valid(observations) or not Data.valid(own):
		return _idle(tick, "invalid_combat_input")
	if not Data.equal(own.get("alive"), true):
		return _idle(tick, "actor_dead")
	if not Data.integer(own.get("blind_until_tick")) or own.blind_until_tick > tick:
		return _idle(tick, "blinded_or_unknown")
	if not Data.equal(own.get("smoke_view_known"), true):
		return _idle(tick, "own_vision_unknown")
	if not Data.equal(own.get("inside_smoke"), false) or not Data.equal(own.get("view_smoked_off"), false):
		return _idle(tick, "own_vision_smoked")
	var contacts: Dictionary = {}
	var losses: Dictionary = {}
	for observation in observations:
		if not observation is Dictionary or not Data.equal(observation.get("bot_id"), _bot_id) or not Data.nonempty(observation.get("id")):
			continue
		if not Data.equal(observation.get("source"), "seen") or not Data.integer(observation.get("event_tick")) or not Data.integer(observation.get("available_tick")):
			continue
		if observation.event_tick > observation.available_tick or observation.available_tick > tick or not observation.get("content") is Dictionary:
			continue
		var content: Dictionary = observation.content
		if not Data.nonempty(content.get("enemy_id")):
			continue
		var enemy: String = content.enemy_id
		if Data.equal(content.get("type"), "enemy_lost") and Data.keys_exact(content, ["type", "enemy_id"]):
			if not losses.has(enemy) or losses[enemy].event_tick < observation.event_tick:
				losses[enemy] = observation
		elif Data.equal(content.get("type"), "enemy_aim") and Data.keys_exact(content, ["type", "enemy_id", "aim_position"]):
			if not _point(content.aim_position):
				continue
			if not contacts.has(enemy) or _newer(observation, contacts[enemy]):
				contacts[enemy] = observation
	var selected: Dictionary = {}
	for enemy in contacts:
		var contact: Dictionary = contacts[enemy]
		if tick >= contact.event_tick + _fresh_ticks:
			continue
		if losses.has(enemy) and losses[enemy].event_tick >= contact.event_tick:
			continue
		if selected.is_empty() or _newer(contact, selected):
			selected = contact
	if selected.is_empty():
		return _idle(tick, "no_fresh_delivered_contact")
	return {"tick": tick, "bot_id": _bot_id, "action": "engage", "reason": "delivered_last_observed_aim",
		"enemy_id": selected.content.enemy_id, "aim_position": selected.content.aim_position.duplicate(),
		"expires_tick": selected.event_tick + _fresh_ticks, "evidence_ids": [selected.id]}

func _idle(tick: int, reason: String) -> Dictionary:
	return {"tick": tick, "bot_id": _bot_id, "action": "idle", "reason": reason,
		"enemy_id": null, "aim_position": null, "expires_tick": tick + 1, "evidence_ids": []}

func _newer(a: Dictionary, b: Dictionary) -> bool:
	return a.event_tick > b.event_tick or (a.event_tick == b.event_tick and a.id < b.id)

func _point(value: Variant) -> bool:
	return value is Array and value.size() == 3 and value.all(func(n: Variant) -> bool: return (n is int or n is float) and is_finite(float(n)))
