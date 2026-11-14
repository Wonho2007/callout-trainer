extends SceneTree
# Optional test: launcher copies Person 2 files into a temporary project only.
const Executor = preload("res://bots/command_executor.gd")
const Reports = preload("res://comms/report_adapter.gd")
const Model = preload("res://belief/region_belief.gd")
const Audit = preload("res://recording/evidence_audit.gd")
var failures: int = 0
var assertions: int = 0

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	var catalog: Dictionary = {"speakers": ["player"], "regions": ["entry", "site", "upper"], "entries": [], "flashes": []}
	var executor: RefCounted = Executor.new("ally_1", catalog, schema)
	var belief: RefCounted = Model.new("ally_1", catalog.regions, ["enemy_1"])
	var own_state: Dictionary = {"alive": true, "flash_count": 1, "reachable_target_ids": []}
	var message: Dictionary = Reports.make_report("call_1", "player", "ally_1", 120, 220, "upper")
	var observation: Dictionary = Reports.told_observation(message, "obs_call_1", 138)
	check(executor.enqueue(observation).ok, "Person 2 inbox accepts Person 3 envelope")
	check(executor.step(137, own_state).reports.is_empty() and executor.inbox.available().is_empty(), "executor releases no early report/evidence")
	var output: Dictionary = executor.step(138, own_state)
	check(output.reports.size() == 1 and output.results[0].status == "completed", "executor processes due report")
	check(output.reports[0].evidence_ids == [observation.id], "executor preserves original evidence ID")
	var released: Array = executor.inbox.available()
	check(released.size() == 1 and belief.apply(released[0], 138).ok, "validated local evidence reaches belief model")
	check(is_equal_approx(belief.snapshot().enemies.enemy_1.upper, 0.933333), "delayed report changes queried belief")
	check(Audit.check(released, [{"tick": 138, "bot_id": "ally_1", "evidence_ids": belief.snapshot().evidence_ids}]).is_empty(), "cross-lane evidence audits")
	var duplicate: Dictionary = observation.duplicate(true)
	duplicate.id = "redelivery"
	duplicate.available_tick = 139
	executor.enqueue(duplicate)
	check(executor.step(139, own_state).reports.is_empty(), "executor does not forward duplicate testimony")
	if failures == 0:
		print("PERSON3_INTEGRATION_PASS: %d assertions" % assertions)
	quit(0 if failures == 0 else 1)
