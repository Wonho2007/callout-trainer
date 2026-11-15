extends SceneTree
# Real Person 3 code is copied READ-ONLY into a disposable test project.
const Belief = preload("res://belief/region_belief.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
var failed: bool = false
var checks: int = 0

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		printerr("FAIL: ", label)
		failed = true

func _initialize() -> void:
	var regions: Array = ["entrance", "logs", "site"]
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	var executor = Executor.new("ally", {"entries": ["entry_a"], "flashes": ["flash_a"], "regions": regions, "speakers": ["player"]}, schema)
	var beliefs = Belief.new("ally", regions, ["enemy"])
	var planner = Planner.new("ally", {
		"regions": regions, "markers": [
			{"id": "home", "watch_regions": ["entrance"], "roles": ["hold", "cover"], "objectives": ["none", "entry", "defuse"]},
			{"id": "logs_cover", "watch_regions": ["logs"], "roles": ["hold", "cover"], "objectives": ["none", "entry", "defuse"]}
		], "baseline_marker_id": "home", "baseline_watch_region": "entrance",
		"threat_threshold": 0.55, "freshness_ticks": 10, "heartbeat_ticks": 3, "switch_margin": 0.1})
	var state: Dictionary = {"alive": true, "marker_id": "home", "reachable_marker_ids": ["home", "logs_cover"], "role": "hold", "objective": "none"}
	var physical: Dictionary = {"alive": true, "flash_count": 1, "reachable_target_ids": ["entry_a", "flash_a"]}
	var report = msg("report", "report", {"action": "report_enemy", "region_id": "logs", "count": 1, "hedge": "sure"}, 0)
	executor.enqueue(obs("r", report, 2))
	var output: Dictionary = executor.step(1, physical)
	expect(output.reports.is_empty(), "report cannot reach beliefs early")
	expect(planner.decide(1, beliefs.snapshot(), state, executor.inbox).decision.target_id == "home", "prior holds before delivery")
	output = executor.step(2, physical)
	expect(output.reports.size() == 1, "validated report released")
	# Keep original observation ID; do not mint fresh evidence from output.reports.
	for record in executor.inbox.available():
		if record.id in output.reports[0].evidence_ids:
			expect(beliefs.apply(record, 2).ok, "Person 3 applies exact released testimony")
	var decision: Dictionary = planner.decide(2, beliefs.snapshot(), state, executor.inbox)
	expect(decision.ok and decision.decision.target_id == "logs_cover", "real beliefs change planner goal")
	expect(decision.decision.evidence_ids == ["r"], "cross-lane provenance preserved")
	var swing = msg("swing", "command", {"action": "swing_together", "target_id": "entry_a", "timing": {"mode": "follow_player"}}, 2)
	executor.enqueue(obs("s", swing, 3))
	executor.step(3, physical)
	decision = planner.decide(3, beliefs.snapshot(), state, executor.inbox, executor.active_command_snapshot())
	expect(decision.decision.goal == "command", "accepted command outranks real beliefs")
	executor.enqueue(obs("cancel", msg("cancel", "cancel", {"command_id": "swing"}, 3), 4))
	executor.step(4, physical)
	decision = planner.decide(4, beliefs.snapshot(), state, executor.inbox, executor.active_command_snapshot())
	expect(decision.decision.target_id == "logs_cover", "autonomy resumes after command cancellation")
	var identity: Dictionary = {}
	for origin in regions:
		identity[origin] = {}
		for destination in regions:
			identity[origin][destination] = 1.0 if origin == destination else 0.0
	expect(beliefs.predict(12, identity), "Person 3 prediction advances snapshot")
	executor.step(12, physical)
	decision = planner.decide(12, beliefs.snapshot(), state, executor.inbox)
	expect(decision.decision.target_id == "home", "prediction does not refresh old testimony")
	print("PERSON2_BELIEF_INTEGRATION_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	quit(1 if failed else 0)

func msg(id: String, kind: String, payload: Dictionary, issued: int) -> Dictionary:
	return {"schema_version": "comms.v1", "message_id": id, "speaker_id": "player", "recipient_id": "ally",
		"issued_tick": issued, "expires_tick": 100, "kind": kind, "payload": payload}

func obs(id: String, message: Dictionary, available: int) -> Dictionary:
	return {"id": id, "bot_id": "ally", "event_tick": message.issued_tick, "available_tick": available,
		"source": "told", "speaker_id": "player", "content": {"type": "comms", "message": message}}
