extends RefCounted
# Pure baseline policy: static annotation, public clock, copied delivered evidence.
# Never receives actors, hidden positions, or player-only recon.
const Retake = preload("res://bots/retake_policy.gd")
var _id: String
var _timeline: Array
var _start_tick: int
var _scenario_tick: int = 0
var _deviated: bool = false
var _evidence: Array = []
var _retake: RefCounted
var _used: Dictionary = {}
var _utility: Array = []
var _smoke_ready: Array = []
var _initial_hp: float = -1.0
var _utility_grace_ticks: int = 120

func _init(id: String, timeline: Array, start_tick: int = 0, utility_grace_ticks: int = 120) -> void:
	_id = id
	_timeline = timeline.duplicate(true)
	_start_tick = start_tick
	_utility_grace_ticks = maxi(0, utility_grace_ticks)
	_scenario_tick = start_tick
	var target: String = "b_upper" if id == "chronicle" else ("b_heaven" if id == "crashies" else "b_pit")
	_retake = Retake.new(id, target)
	_smoke_ready = [0, 1080] if id == "ally" else [0, 2760]

func set_scenario_tick(tick: int) -> void:
	_scenario_tick = tick

func _reference_region(actor: String, at: int) -> String:
	var region: String = ""
	for beat in _timeline:
		if beat.actor_id == actor and int(beat.tick) <= at and beat.action in ["hold", "reference_hold", "reference_move", "first_known_position", "reference_last_position"]:
			region = beat.region
	return region

func consider_player_plan(active: Dictionary) -> void:
	if _id == "ally" and not active.is_empty():
		_deviated = true
		_evidence = active.evidence_ids.duplicate()

func decide(tick: int, observations: Array, own: Dictionary) -> Dictionary:
	if _initial_hp < 0:
		_initial_hp = float(own.get("hp", 0))
	if float(own.get("hp", _initial_hp)) < _initial_hp:
		_deviated = true
	for observation in observations:
		if observation.get("bot_id") != _id or int(observation.get("available_tick", tick + 1)) > tick:
			continue
		var content: Dictionary = observation.get("content", {})
		if _id == "ally" and observation.get("source") == "told" and content.get("message", {}).get("kind") == "report":
			_deviated = true
			_evidence = [observation.id]
		elif observation.get("source") == "seen" and content.get("type") == "enemy_seen":
			var event_scenario_tick: int = _start_tick + int(observation.event_tick)
			var expected: String = _reference_region(content.get("enemy_id", ""), event_scenario_tick)
			# A small boundary tolerance avoids treating normal physical traversal
			# around a coarse annotation beat as a tactical deviation.
			var before: String = _reference_region(content.get("enemy_id", ""), maxi(0, event_scenario_tick - 120))
			var after: String = _reference_region(content.get("enemy_id", ""), event_scenario_tick + 120)
			if not expected.is_empty() and content.get("region_id") not in [expected, before, after]:
				_deviated = true
				_evidence = [observation.id]
	if not own.get("alive", false):
		return _decision(tick, "stop", null, null, "actor_dead")
	if _deviated:
		_utility.clear()
		if _id == "ally":
			return {} # Existing evidence-based teammate planner now owns the goals.
		var reactive: Dictionary = _retake.decide(tick, observations, own)
		for id in _evidence:
			if id not in reactive.evidence_ids:
				reactive.evidence_ids.append(id)
		reactive.reason = "observed_deviation_" + reactive.reason
		return reactive
	var target: String = _reference_region(_id, _scenario_tick)
	if target.is_empty() or target not in own.get("reachable_marker_ids", []):
		return _decision(tick, "stop", null, null, "annotation_no_reachable_goal")
	_queue_utility(own)
	var watch: String = "b_pit" if _id != "ally" else target
	return _decision(tick, "hold" if own.get("marker_id") == target else "reposition", target, watch, "annotation_baseline")

func _queue_utility(own: Dictionary) -> void:
	for index in range(_timeline.size()):
		var beat: Dictionary = _timeline[index]
		if beat.actor_id != _id or beat.action not in ["reference_smoke", "reference_grenade", "reference_recon"] or index in _used or int(beat.tick) > _scenario_tick:
			continue
		# Never replay missed throws later in the round, while blind, or from
		# the wrong staging region after physical displacement.
		if _scenario_tick > int(beat.tick) + _utility_grace_ticks:
			_used[index] = true
			continue
		var stage: String = _reference_region(_id, int(beat.tick))
		if own.get("marker_id") != stage or own.get("blinded", false) or own.get("engaged", false):
			continue
		if beat.action == "reference_smoke":
			var charge: int = -1
			for slot in range(_smoke_ready.size()):
				if int(_smoke_ready[slot]) <= _scenario_tick:
					charge = slot
					break
			if charge < 0:
				continue
			_smoke_ready[charge] = _scenario_tick + 1800
		_used[index] = true
		_utility.append(beat.duplicate(true))

func take_utility() -> Array:
	var result: Array = _utility.duplicate(true)
	_utility.clear()
	return result

func snapshot() -> Dictionary:
	return {"deviated": _deviated, "scenario_tick": _scenario_tick, "evidence_ids": _evidence.duplicate()}

func _decision(tick: int, goal: String, target: Variant, watch: Variant, reason: String) -> Dictionary:
	return {"tick": tick, "bot_id": _id, "goal": goal, "target_id": target,
		"watch_region_id": watch, "evidence_ids": [], "reason": reason, "score": 0.0}
