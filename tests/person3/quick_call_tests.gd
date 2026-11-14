extends SceneTree
# Headless assertions for the pure quick-call model. No scene, input or world.
const QuickCall = preload("res://comms/quick_call.gd")
const Reports = preload("res://comms/report_adapter.gd")
var failures: Array = []
var assertions: int = 0

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func model() -> RefCounted:
	return QuickCall.new("player", ["entry", "site", "upper"], ["entry_a"], ["flash_a"])

func _initialize() -> void:
	var qc: RefCounted = model()

	# Menu exposes only the known vocabulary, no world coordinates.
	var menu: Dictionary = qc.menu()
	check(menu.report.regions == ["entry", "site", "upper"], "menu lists known regions only")
	check(menu.report.hedges == ["sure", "think", "unsure"], "menu offers the three hedges")
	check(menu.command.swing_together.targets == ["entry_a"], "swing uses authored entry markers")
	check(menu.command.throw_flash.targets == ["flash_a"], "flash uses authored flash markers")
	check(menu.command.throw_flash.timings == ["now", "on_cue"], "flash excludes follow_player")
	check(menu.command.swing_together.timings == ["now", "on_cue", "follow_player"], "swing allows all timings")

	# A report selection produces a schema-valid comms.v1 report via the adapter.
	var report: Dictionary = qc.report("qc_0", "ally_1", 120, 220, "upper", null, "sure")
	check(Reports.valid_report(report), "quick-call report is a valid comms.v1 report")
	check(report.speaker_id == "player" and report.recipient_id == "ally_1", "report addresses one bot from the panel speaker")
	check(report.payload.region_id == "upper" and report.payload.hedge == "sure", "report carries the selected region and hedge")
	var told: Dictionary = Reports.told_observation(report, "obs_qc_0", 138)
	check(not told.is_empty() and told.source == "told", "report converts to a delayed told observation")

	# Unknown region never emits a message (no invented coordinates).
	check(qc.report("qc_x", "ally_1", 120, 220, "nowhere").is_empty(), "unknown region yields no message")
	check(qc.report("qc_x", "ally_1", 120, 220, "upper", null, "maybe").is_empty(), "unknown hedge yields no message")
	check(qc.report("qc_x", "ally_1", 220, 220, "upper").is_empty(), "non-positive expiry window rejected")
	check(qc.report("qc_x", "ally_1", 120, 220, "upper", 0).is_empty(), "zero count rejected")
	check(not qc.report("qc_x", "ally_1", 120, 220, "upper", 2, "think").is_empty(), "explicit positive count accepted")

	# Commands validate action/target/timing against the catalog.
	var swing: Dictionary = qc.command("qc_1", "ally_1", 120, 220, "swing_together", "entry_a", "follow_player")
	check(not swing.is_empty() and swing.kind == "command", "swing command is built")
	check(swing.payload.action == "swing_together" and swing.payload.timing.mode == "follow_player", "swing timing preserved")
	var flash: Dictionary = qc.command("qc_2", "ally_1", 120, 220, "throw_flash", "flash_a", "now")
	check(not flash.is_empty() and flash.payload.action == "throw_flash", "flash command is built")
	check(qc.command("qc_x", "ally_1", 120, 220, "throw_flash", "flash_a", "follow_player").is_empty(), "flash rejects follow_player timing")
	check(qc.command("qc_x", "ally_1", 120, 220, "swing_together", "flash_a", "now").is_empty(), "swing rejects a flash marker target")
	check(qc.command("qc_x", "ally_1", 120, 220, "throw_flash", "entry_a", "now").is_empty(), "flash rejects an entry marker target")
	check(qc.command("qc_x", "ally_1", 120, 220, "defuse", "entry_a", "now").is_empty(), "unsupported action rejected")

	# Cue/cancel reference an existing command by ID.
	var cue: Dictionary = qc.make_reference("qc_3", "ally_1", 130, 220, "cue", "qc_1")
	check(not cue.is_empty() and cue.kind == "cue" and cue.payload.command_id == "qc_1", "cue references a command id")
	var cancel: Dictionary = qc.make_reference("qc_4", "ally_1", 130, 220, "cancel", "qc_1")
	check(not cancel.is_empty() and cancel.kind == "cancel", "cancel references a command id")
	check(qc.make_reference("qc_x", "ally_1", 130, 220, "report", "qc_1").is_empty(), "non reference kind rejected")

	# Repeated calls throughout the round are supported with distinct ids.
	var a: Dictionary = qc.report("call_a", "ally_1", 120, 220, "upper")
	var b: Dictionary = qc.report("call_b", "ally_1", 300, 400, "site")
	check(a.message_id != b.message_id and a.payload.region_id != b.payload.region_id, "repeated distinct calls are supported")

	# A model with no markers still reports but offers no commands.
	var report_only: RefCounted = QuickCall.new("player", ["entry", "site"])
	check(report_only.menu().command.swing_together.targets.is_empty(), "no entry markers means no swing targets")
	check(not report_only.report("qc_0", "ally_1", 1, 10, "site").is_empty(), "report-only quick-call still works")
	check(report_only.command("qc_0", "ally_1", 1, 10, "swing_together", "entry_a", "now").is_empty(), "no markers means no buildable command")

	# Acknowledgment mapping honours the "no Ready before executor ready" rule.
	check(QuickCall.acknowledgment("ready") == "Ready", "ready maps to Ready")
	check(QuickCall.acknowledgment("accepted") != "Ready", "accepted never claims Ready")
	check(QuickCall.acknowledgment("executing") == "Flashing", "executing maps to Flashing")
	check(QuickCall.acknowledgment("rejected", "no_utility") == "No flash left", "no_utility maps to No flash left")
	check(QuickCall.acknowledgment("completed") == "", "completed is silent")

	if failures.is_empty():
		print("PERSON3_QUICKCALL_PASS: %d assertions" % assertions)
		quit(0)
	else:
		quit(1)
