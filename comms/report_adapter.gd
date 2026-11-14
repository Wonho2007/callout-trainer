extends RefCounted
# Structured/menu fallback only. IDs, ticks and expiry come from the trusted caller.
const Values = preload("res://belief/plain_values.gd")

static func make_report(message_id: String, speaker_id: String, recipient_id: String,
		issued_tick: int, expires_tick: int, region_id: String,
		count: Variant = null, hedge: String = "sure") -> Dictionary:
	var message: Dictionary = {
		"schema_version": "comms.v1", "message_id": message_id,
		"speaker_id": speaker_id, "recipient_id": recipient_id,
		"issued_tick": issued_tick, "expires_tick": expires_tick, "kind": "report",
		"payload": {"action": "report_enemy", "region_id": region_id, "count": count, "hedge": hedge}}
	return message if valid_report(message) else {}

static func valid_report(message: Dictionary) -> bool:
	if not Values.valid(message) or not Values.keys(message,
			["schema_version", "message_id", "speaker_id", "recipient_id", "issued_tick", "expires_tick", "kind", "payload"]):
		return false
	if message.schema_version != "comms.v1" or message.kind != "report":
		return false
	for key in ["message_id", "speaker_id", "recipient_id"]:
		if not Values.text(message[key]):
			return false
	if not Values.integer(message.issued_tick) or not Values.integer(message.expires_tick) or message.expires_tick <= message.issued_tick:
		return false
	if not message.payload is Dictionary or not Values.keys(message.payload, ["action", "region_id", "count", "hedge"]):
		return false
	var payload: Dictionary = message.payload
	return payload.action == "report_enemy" and Values.text(payload.region_id) and payload.hedge in ["sure", "think", "unsure"] and (payload.count == null or (Values.integer(payload.count) and payload.count > 0))

static func told_observation(message: Dictionary, observation_id: String, available_tick: int) -> Dictionary:
	if not valid_report(message) or not Values.text(observation_id) or available_tick < message.issued_tick:
		return {}
	return {"id": observation_id, "bot_id": message.recipient_id,
		"event_tick": message.issued_tick, "available_tick": available_tick,
		"source": "told", "speaker_id": message.speaker_id,
		"content": {"type": "comms", "message": message.duplicate(true)}}
