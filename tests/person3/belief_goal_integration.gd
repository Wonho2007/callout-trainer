extends SceneTree
# Person 3 integration harness for the hour-8 gate: a delayed quick-call changes a
# bot's goal. It drives Person 3's quick-call + belief code through Person 2's real
# executor/inbox/planner, which the wrapper copies READ-ONLY into a temporary
# project. No world, scene, main.tscn or live actor is used; the only "actor state"
# is a plain copied dictionary. This proves the information path, not gameplay.
const QuickCall = preload("res://comms/quick_call.gd")
const Reports = preload("res://comms/report_adapter.gd")
const Belief = preload("res://belief/region_belief.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
const Audit = preload("res://recording/evidence_audit.gd")
var failures: Array = []
var assertions: int = 0

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func _initialize() -> void:
	var regions: Array = ["entrance", "logs", "site"]
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))

	# Person 2 lane objects, same configuration as its own fixture.
	var executor: RefCounted = Executor.new("ally_1", {"entries": ["entry_a"], "flashes": ["flash_a"],
		"regions": regions, "speakers": ["player"]}, schema)
	var belief: RefCounted = Belief.new("ally_1", regions, ["enemy_1"])
	var planner: RefCounted = Planner.new("ally_1", {
		"regions": regions, "markers": [
			{"id": "home", "watch_regions": ["entrance"], "roles": ["hold", "cover"], "objectives": ["none", "entry", "defuse"]},
			{"id": "logs_cover", "watch_regions": ["logs"], "roles": ["hold", "cover"], "objectives": ["none", "entry"]}],
		"baseline_marker_id": "home", "baseline_watch_region": "entrance",
		"threat_threshold": 0.55, "freshness_ticks": 10, "heartbeat_ticks": 3, "switch_margin": 0.1})

	var goal_state: Dictionary = {"alive": true, "marker_id": "home",
		"reachable_marker_ids": ["home", "logs_cover"], "role": "hold", "objective": "none"}
	var physical_state: Dictionary = {"alive": true, "flash_count": 1, "reachable_target_ids": ["entry_a", "flash_a"]}

	# Person 3 produces the call. The player quick-calls an enemy in "logs" at tick 1.
	var panel_model: RefCounted = QuickCall.new("player", regions, ["entry_a"], ["flash_a"])
	var message: Dictionary = panel_model.report("qc_logs", "ally_1", 1, 101, "logs", 1, "sure")
	check(not message.is_empty(), "quick-call builds a logs report")

	# A trusted adapter turns it into a delayed told observation (reaction delay to
	# tick 3) and queues it in Person 2's inbox. It must not reach beliefs early.
	var observation: Dictionary = Reports.told_observation(message, "obs_qc_logs", 3)
	check(not observation.is_empty(), "report becomes a delayed told observation")
	check(executor.enqueue(observation).ok, "Person 2 inbox accepts the quick-call envelope")

	# Baseline before delivery: planner holds the home angle, no logs threat yet.
	var early: Dictionary = executor.step(1, physical_state)
	check(early.reports.is_empty(), "no report released before the reaction delay elapses")
	var baseline_decision: Dictionary = planner.decide(1, belief.snapshot(), goal_state, executor.inbox)
	check(baseline_decision.ok and baseline_decision.decision.target_id == "home", "prior holds the baseline marker")
	check(baseline_decision.decision.watch_region_id == "entrance", "baseline watches the entrance")

	# Still early at tick 2.
	check(executor.step(2, physical_state).reports.is_empty(), "report still withheld at tick 2")

	# Delivery tick: executor validates and releases the report.
	var released_step: Dictionary = executor.step(3, physical_state)
	check(released_step.reports.size() == 1, "executor releases the validated report at the delayed tick")
	check(released_step.results[0].status == "completed", "report lifecycle completes")
	check(released_step.reports[0].evidence_ids == ["obs_qc_logs"], "original evidence id is preserved, not re-minted")

	# Person 3 applies the exact released observation to beliefs (no fresh evidence).
	var applied: bool = false
	for record in executor.inbox.available():
		if record.id in released_step.reports[0].evidence_ids:
			applied = belief.apply(record, 3).ok
	check(applied, "belief model applies the released testimony")
	check(is_equal_approx(belief.snapshot().enemies.enemy_1.logs, 0.933333), "sure report commits belief mass toward logs")

	# Goal change: the planner now repositions to cover the reported region.
	var reactive: Dictionary = planner.decide(3, belief.snapshot(), goal_state, executor.inbox)
	check(reactive.ok, "planner accepts the updated belief")
	check(reactive.decision.target_id == "logs_cover", "delayed quick-call changes the bot goal")
	check(reactive.decision.watch_region_id == "logs", "bot now watches the reported region")
	check(reactive.decision.evidence_ids == ["obs_qc_logs"], "goal cites the quick-call evidence")
	check(reactive.replanned, "the belief change triggers a replan")

	# Fairness membership/time audit over the cross-lane evidence.
	var audit_errors: Array = Audit.check(executor.inbox.available(),
		[{"tick": 3, "bot_id": "ally_1", "evidence_ids": reactive.decision.evidence_ids}])
	check(audit_errors.is_empty(), "goal evidence passes the membership/time audit")

	# Idempotence across the whole path: re-delivering the same message id cannot
	# apply the testimony twice or spawn a second report.
	var redelivery: Dictionary = observation.duplicate(true)
	redelivery.id = "obs_qc_logs_again"
	redelivery.available_tick = 4
	executor.enqueue(redelivery)
	var again: Dictionary = executor.step(4, physical_state)
	check(again.reports.is_empty(), "duplicate message id does not forward a second report")

	# A later, higher-count call keeps working (repeated calls through the round).
	var second: Dictionary = panel_model.report("qc_logs_2", "ally_1", 5, 105, "logs", 2, "think")
	var second_obs: Dictionary = Reports.told_observation(second, "obs_qc_logs_2", 7)
	executor.enqueue(second_obs)
	check(executor.step(7, physical_state).reports.size() == 1, "a later distinct quick-call is a new request")

	if failures.is_empty():
		print("PERSON3_GOAL_INTEGRATION_PASS: %d assertions" % assertions)
		quit(0)
	else:
		quit(1)
