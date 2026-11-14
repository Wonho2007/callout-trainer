extends RefCounted
const Model = preload("res://belief/region_belief.gd")
const Values = preload("res://belief/plain_values.gd")

# Fixed observations only. No world simulation and no counterfactual combat claims.
# Optional transition entries are {tick, matrix}; same-tick prediction precedes evidence.
static func run(bot_id: String, regions: Array, enemies: Array, observations: Array,
		transitions: Array = []) -> Dictionary:
	if not Values.valid(observations) or not Values.valid(transitions):
		return {"ok": false, "reason": "non_plain_input"}
	var events: Array = []
	for observation in observations:
		if not observation is Dictionary or not Values.integer(observation.get("available_tick")) or not Values.integer(observation.get("event_tick")) or not Values.text(observation.get("id")):
			return {"ok": false, "reason": "invalid_observation"}
		events.append({"tick": observation.available_tick, "order": 1, "event_tick": observation.event_tick, "id": observation.id, "value": observation.duplicate(true)})
	for transition in transitions:
		if not transition is Dictionary or not Values.keys(transition, ["tick", "matrix"]) or not Values.integer(transition.tick) or not transition.matrix is Dictionary:
			return {"ok": false, "reason": "invalid_transition"}
		events.append({"tick": transition.tick, "order": 0, "event_tick": transition.tick, "id": "", "value": transition.matrix.duplicate(true)})
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.tick != b.tick:
			return a.tick < b.tick
		if a.order != b.order:
			return a.order < b.order
		if a.event_tick != b.event_tick:
			return a.event_tick < b.event_tick
		return a.id < b.id)
	var model: RefCounted = Model.new(bot_id, regions, enemies)
	var snapshots: Array = [model.snapshot()]
	for event in events:
		if event.order == 0:
			if not model.predict(event.tick, event.value):
				return {"ok": false, "reason": "invalid_transition"}
		else:
			var result: Dictionary = model.apply(event.value, event.tick)
			if not result.ok:
				return result
		snapshots.append(model.snapshot())
	return {"ok": true, "snapshots": snapshots, "final": model.snapshot()}
