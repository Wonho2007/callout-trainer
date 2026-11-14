extends RefCounted
const Values = preload("res://belief/plain_values.gd")

# Privileged offline validator. Never pass the whole archive to a bot.
# Membership/time audit only; dependency and perturbation tests are separate.
static func check(observations: Array, decisions: Array) -> Array:
	var errors: Array = []
	var indexed: Dictionary = {}
	for observation in observations:
		if not observation is Dictionary or not Values.valid(observation) or not Values.keys(observation,
				["id", "bot_id", "event_tick", "available_tick", "source", "speaker_id", "content"]):
			errors.append("invalid_observation")
			continue
		if not Values.text(observation.id) or not Values.text(observation.bot_id) or not Values.integer(observation.event_tick) or not Values.integer(observation.available_tick) or observation.available_tick < observation.event_tick:
			errors.append("invalid_observation_time_or_id")
			continue
		if observation.source not in ["seen", "heard", "told"] or not Values.text(observation.speaker_id) or not observation.content is Dictionary:
			errors.append("invalid_observation_content")
			continue
		var key: String = JSON.stringify([observation.bot_id, observation.id])
		if indexed.has(key):
			errors.append("duplicate_observation:" + key)
		indexed[key] = observation
	for decision in decisions:
		if not decision is Dictionary or not Values.valid(decision) or not Values.text(decision.get("bot_id")) or not Values.integer(decision.get("tick")) or not decision.get("evidence_ids") is Array:
			errors.append("invalid_decision")
			continue
		var used: Dictionary = {}
		for id in decision.evidence_ids:
			if not Values.text(id):
				errors.append("invalid_evidence_id")
				continue
			if used.has(id):
				errors.append("duplicate_evidence_id:" + id)
			used[id] = true
			var key: String = JSON.stringify([decision.bot_id, id])
			if not indexed.has(key):
				errors.append("missing_or_foreign_evidence:" + key)
			elif indexed[key].available_tick > decision.tick:
				errors.append("future_evidence:" + key)
	return errors
