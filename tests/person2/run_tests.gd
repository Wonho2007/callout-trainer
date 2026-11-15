extends SceneTree

const Inbox = preload("res://perception/observation_inbox.gd")
const Executor = preload("res://bots/command_executor.gd")
const FakeActor = preload("res://tests/person2/fake_actor.gd")
const Validator = preload("res://validation/comms_validator.gd")
var failures: Array[String] = []
var checks: int = 0
var schema: Dictionary

func _initialize() -> void:
	schema = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	test_inbox()
	test_leak_fixture()
	test_follow_swing()
	test_cues()
	test_flash_and_duplicates()
	test_supersession_and_reports()
	test_expiry_death_and_failures()
	test_validation()
	test_hidden_state()
	test_edge_cases()
	test_review_regressions()
	test_wrong_type_matrix()
	if failures.is_empty():
		print("PERSON2_TESTS_PASS checks=", checks)
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append("FAIL: " + label)

func message(id: String, kind: String, payload: Dictionary, issued: int = 0, expires: int = 100) -> Dictionary:
	return {"schema_version": "comms.v1", "message_id": id, "speaker_id": "player", "recipient_id": "ally",
		"issued_tick": issued, "expires_tick": expires, "kind": kind, "payload": payload}

func swing(id: String = "s1", mode: String = "follow_player", expires: int = 100) -> Dictionary:
	return message(id, "command", {"action": "swing_together", "target_id": "entry",
		"timing": {"mode": mode}}, 0, expires)

func flash(id: String = "f1") -> Dictionary:
	return message(id, "command", {"action": "throw_flash", "target_id": "flash",
		"timing": {"mode": "now"}})

func observation(id: String, content: Dictionary, available: int = 2, source: String = "told", event: int = 0) -> Dictionary:
	return {"id": id, "bot_id": "ally", "event_tick": event, "available_tick": available,
		"source": source, "speaker_id": "player", "content": content}

func told(id: String, msg: Dictionary, available: int = 2) -> Dictionary:
	return observation(id, {"type": "comms", "message": msg}, available, "told", int(msg.get("issued_tick", 0)))

func make_executor() -> RefCounted:
	return Executor.new("ally", {"entries": ["entry"], "flashes": ["flash"], "regions": ["logs"],
		"speakers": ["player"]}, schema, 10)

func audit(output: Dictionary, inbox: RefCounted, tick: int) -> void:
	for group in ["results", "intents", "reports"]:
		for entry in output[group]:
			for evidence_id in entry["evidence_ids"]:
				expect(inbox.evidence_available(evidence_id, tick), "all outputs cite available bot-local evidence")

func has_status(output: Dictionary, id: String, status: String, reason: String = "") -> bool:
	for result in output["results"]:
		if result.message_id == id and result.status == status and (reason.is_empty() or result.reason_code == reason):
			return true
	return false

func test_inbox() -> void:
	var inbox = Inbox.new("ally")
	var obs = told("o1", swing())
	expect(inbox.enqueue(obs).ok, "inbox accepts copied observation")
	obs.content.message.payload.target_id = "changed"
	expect(inbox.release(1).is_empty(), "no early delivery")
	expect(not inbox.evidence_available("o1", 2), "cannot query future evidence")
	var due: Array = inbox.release(2)
	expect(due.size() == 1 and due[0].content.message.payload.target_id == "entry", "input copied")
	due[0].content.message.payload.target_id = "mutated"
	expect(inbox.available()[0].content.message.payload.target_id == "entry", "output copied")
	expect(inbox.enqueue(told("o1", swing())).ok, "identical observation deduplicated")
	expect(inbox.release(3).is_empty(), "no duplicate release")
	var foreign = told("other", swing())
	foreign.bot_id = "enemy"
	expect(not inbox.enqueue(foreign).ok, "foreign observation rejected")
	var early = told("early", swing())
	early.event_tick = 5
	expect(not inbox.enqueue(early).ok, "availability before event rejected")
	expect(not inbox.enqueue(told("o1", flash())).ok, "observation ID collision rejected")
	expect(inbox.release(1).is_empty() and inbox.current_tick() == 3, "clock cannot go backward")
	var object_obs = told("object", swing())
	object_obs.content["node"] = Node.new()
	expect(not inbox.enqueue(object_obs).ok, "live object cannot enter inbox")
	object_obs.content.node.free()

func test_leak_fixture() -> void:
	var inbox = Inbox.new("ally")
	inbox.enqueue(told("delayed", swing(), 8))
	inbox.release(7)
	expect(not inbox.evidence_available("delayed", 7), "leak fixture rejects future evidence")
	expect(not inbox.evidence_available("nonexistent", 7), "leak fixture rejects fabricated evidence")
	inbox.release(8)
	expect(inbox.evidence_available("delayed", 8), "evidence accepted at delivery boundary")

func test_follow_swing() -> void:
	var executor = make_executor()
	var actor = FakeActor.new()
	executor.enqueue(told("sight", swing()))
	expect(executor.step(1, actor.snapshot()).intents.is_empty(), "executor respects message delay")
	var output: Dictionary = executor.step(2, actor.snapshot())
	expect(has_status(output, "s1", "accepted") and output.intents[0].op == "stage", "swing begins staging")
	actor.apply(output.intents)
	output = executor.step(3, actor.snapshot(), actor.take_feedback())
	expect(has_status(output, "s1", "ready") and output.intents.is_empty(), "ready waits for player")
	executor.enqueue(observation("move", {"type": "player_entry", "actor_id": "player", "entry_id": "entry"}, 5, "seen", 4))
	expect(executor.step(4, actor.snapshot()).intents.is_empty(), "movement reaction delay")
	output = executor.step(5, actor.snapshot())
	expect(has_status(output, "s1", "executing") and output.intents[0].op == "start_swing", "observed movement starts swing")
	expect(output.intents[0].evidence_ids == ["sight", "move"], "swing cites command and movement")
	audit(output, executor.inbox, 5)
	actor.apply(output.intents)
	output = executor.step(6, actor.snapshot(), actor.take_feedback())
	expect(has_status(output, "s1", "completed"), "fake movement completion")
	# Future advance cannot invalidate audit of older results.
	audit(output, executor.inbox, 6)

func test_cues() -> void:
	var executor = make_executor()
	var actor = FakeActor.new()
	executor.enqueue(told("arm", swing("armed", "on_cue")))
	executor.enqueue(told("premature", message("c0", "cue", {"command_id": "armed"})))
	var output: Dictionary = executor.step(2, actor.snapshot())
	expect(has_status(output, "c0", "rejected", "not_ready"), "unready cue rejected")
	actor.apply(output.intents)
	executor.step(3, actor.snapshot(), actor.take_feedback())
	expect(executor.step(4, actor.snapshot()).intents.is_empty(), "rejected cue not latched")
	executor.enqueue(told("go", message("c1", "cue", {"command_id": "armed"}, 4, 10), 5))
	output = executor.step(5, actor.snapshot())
	expect(has_status(output, "armed", "executing") and has_status(output, "c1", "completed"), "ready cue starts action")
	audit(output, executor.inbox, 5)
	var other = make_executor()
	other.enqueue(told("a", swing("a", "on_cue")))
	other.step(2, actor.snapshot())
	other.step(3, actor.snapshot(), [{"command_id": "a", "phase": "staged"}])
	var wrong = message("wrong", "cue", {"command_id": "a"})
	wrong.speaker_id = "stranger"
	var wrong_obs = told("wrong_obs", wrong, 4)
	wrong_obs.speaker_id = "stranger"
	other.enqueue(wrong_obs)
	expect(has_status(other.step(4, actor.snapshot()), "wrong", "rejected"), "unknown speaker cannot release action")
	var late = message("late", "cue", {"command_id": "a"}, 0, 5)
	other.enqueue(told("late_obs", late, 5))
	expect(has_status(other.step(5, actor.snapshot()), "late", "rejected", "expired"), "cue expiry is exclusive")

func test_flash_and_duplicates() -> void:
	var executor = make_executor()
	var actor = FakeActor.new()
	executor.enqueue(told("f", flash()))
	var output: Dictionary = executor.step(2, actor.snapshot())
	expect(has_status(output, "f1", "executing"), "flash executes without staging for now")
	actor.apply(output.intents)
	executor.enqueue(told("repeat", flash(), 3))
	output = executor.step(3, actor.snapshot())
	expect(output.intents.is_empty() and has_status(output, "f1", "executing"), "duplicate command does not throw twice")
	executor.enqueue(told("replacement", swing("replacement"), 4))
	output = executor.step(4, actor.snapshot())
	expect(has_status(output, "replacement", "rejected", "busy_committed"), "committed flash cannot be superseded")
	output = executor.step(5, actor.snapshot(), actor.take_feedback())
	expect(has_status(output, "f1", "completed") and actor.flashes_thrown == 1, "one physical flash")
	executor.enqueue(told("empty", flash("f2"), 6))
	expect(has_status(executor.step(6, actor.snapshot()), "f2", "rejected", "no_utility"), "no flash remaining rejected")
	executor.enqueue(told("id_collision", swing("f1"), 7))
	expect(has_status(executor.step(7, actor.snapshot()), "f1", "rejected", "invalid_message"), "changed payload with reused ID rejected")

func test_supersession_and_reports() -> void:
	var executor = make_executor()
	var actor = FakeActor.new()
	executor.enqueue(told("s", swing()))
	executor.step(2, actor.snapshot())
	executor.enqueue(told("report", message("r", "report", {"action": "report_enemy", "region_id": "logs", "count": 1, "hedge": "think"}), 3))
	var output: Dictionary = executor.step(3, actor.snapshot())
	expect(output.reports.size() == 1 and executor.active_command_id() == "s1", "report forwarded without replacing swing")
	expect(output.reports[0].payload.hedge == "think", "testimony hedge preserved, not confirmed truth")
	executor.enqueue(told("new", swing("s2"), 4))
	output = executor.step(4, actor.snapshot())
	expect(has_status(output, "s1", "cancelled", "superseded") and executor.active_command_id() == "s2", "feasible command supersedes")
	expect(output.intents[0].op == "stop", "old movement stopped before new staging")
	executor.enqueue(told("cancel", message("cancel", "cancel", {"command_id": "s2"}), 5))
	output = executor.step(5, actor.snapshot())
	expect(has_status(output, "s2", "cancelled", "cancelled_by_player") and executor.active_command_id().is_empty(), "cancellation terminates movement")
	audit(output, executor.inbox, 5)

func test_expiry_death_and_failures() -> void:
	var actor = FakeActor.new()
	var executor = make_executor()
	executor.enqueue(told("s", swing("short", "on_cue", 4)))
	executor.step(2, actor.snapshot())
	var output: Dictionary = executor.step(4, actor.snapshot())
	expect(has_status(output, "short", "expired") and output.intents[0].op == "stop", "pending action expires and stops")
	executor = make_executor()
	executor.enqueue(told("s", swing()))
	executor.step(2, actor.snapshot())
	actor.alive = false
	expect(has_status(executor.step(3, actor.snapshot()), "s1", "failed", "actor_dead"), "death terminates accepted action")
	actor.alive = true
	executor = make_executor()
	executor.enqueue(told("s", swing()))
	executor.step(2, actor.snapshot())
	output = executor.step(3, actor.snapshot(), [{"command_id": "stale", "phase": "completed"}])
	expect(not has_status(output, "s1", "completed"), "stale actor feedback ignored")
	output = executor.step(4, actor.snapshot(), [{"command_id": "s1", "phase": "failed"}])
	expect(has_status(output, "s1", "failed", "execution_failed"), "physical failure reported")
	executor = make_executor()
	executor.enqueue(told("f", flash()))
	executor.step(2, actor.snapshot())
	expect(has_status(executor.step(12, actor.snapshot()), "f1", "failed", "execution_failed"), "missing committed completion times out")
	expect(executor.step(11, actor.snapshot()).errors == ["non_monotonic_tick"], "executor rejects backward clock")

func test_validation() -> void:
	var actor = FakeActor.new()
	var executor = make_executor()
	var malformed = swing()
	malformed.payload["hidden_position"] = [0, 0, 0]
	executor.enqueue(told("bad", malformed))
	expect(has_status(executor.step(2, actor.snapshot()), "s1", "rejected", "invalid_message"), "strict schema rejects extra hidden fields")
	executor = make_executor()
	var unknown = swing()
	unknown.payload.target_id = "unknown"
	executor.enqueue(told("unknown", unknown))
	expect(has_status(executor.step(2, actor.snapshot()), "s1", "rejected", "unknown_target"), "known target allowlist")
	executor = make_executor()
	actor.reachable = []
	executor.enqueue(told("unreachable", swing()))
	expect(has_status(executor.step(2, actor.snapshot()), "s1", "rejected", "unreachable"), "unreachable target")
	actor.reachable = ["entry", "flash"]
	executor = make_executor()
	var spoof = swing()
	spoof.recipient_id = "other"
	executor.enqueue(told("spoof", spoof))
	expect(has_status(executor.step(2, actor.snapshot()), "s1", "rejected", "invalid_message"), "recipient mismatch")
	executor = make_executor()
	executor.enqueue(told("old", swing("old", "now", 2)))
	expect(has_status(executor.step(2, actor.snapshot()), "old", "rejected", "expired"), "expired initial command")
	executor = make_executor()
	var future = swing()
	future.issued_tick = 9
	executor.enqueue(observation("future", {"type": "comms", "message": future}))
	expect(has_status(executor.step(2, actor.snapshot()), "s1", "rejected", "invalid_message"), "future-issued command")
	var validator = Validator.new(schema)
	for fixture in JSON.parse_string(FileAccess.get_file_as_string("res://examples/comms_v1.json")).cases:
		expect(validator.valid(fixture.message), "schema matches authored example")
	var broken_state: Dictionary = actor.snapshot()
	broken_state["hidden_enemy"] = [1, 2, 3]
	expect(executor.step(3, broken_state).errors == ["invalid_actor_state"], "own-state allowlist excludes hidden world state")

func hidden_run(hidden_position: Array) -> Array:
	# A fake privileged world exists outside the policy. Only own state and delayed
	# messages cross the boundary, so changing this hidden field must do nothing.
	var world = {"enemy": hidden_position, "own": FakeActor.new()}
	var executor = make_executor()
	executor.enqueue(told("s", swing("s", "on_cue")))
	var outputs: Array = []
	outputs.append(executor.step(2, world.own.snapshot()))
	outputs.append(executor.step(3, world.own.snapshot(), [{"command_id": "s", "phase": "staged"}]))
	return outputs

func test_hidden_state() -> void:
	expect(hidden_run([1, 2, 3]) == hidden_run([99, -4, 50]), "unseen enemy perturbation leaves outputs identical")
	for file in ["res://bots/command_executor.gd", "res://perception/observation_inbox.gd"]:
		var code = FileAccess.get_file_as_string(file)
		for forbidden in ["get_node(", "get_tree(", "get_nodes_in_group(", "global_position", "SceneTree", "FileAccess", "Callable"]:
			expect(not code.contains(forbidden), "restricted dependency scan: " + forbidden)
		var dynamic_load = RegEx.new()
		dynamic_load.compile("(^|[^A-Za-z_])load\\(")
		expect(dynamic_load.search(code) == null, "no dynamic scene/resource loading")

func test_edge_cases() -> void:
	var inbox = Inbox.new("ally")
	inbox.release(5)
	inbox.enqueue(told("late", swing(), 2))
	inbox.release(10)
	expect(not inbox.evidence_available("late", 2), "late evidence cannot backdate an audit")
	expect(inbox.evidence_available("late", 10), "late evidence usable when actually delivered")
	var actor = FakeActor.new()
	var executor = make_executor()
	executor.enqueue(told("s", swing("s", "on_cue")))
	executor.step(2, actor.snapshot())
	var bad = flash("bad")
	bad.payload.target_id = "unknown"
	executor.enqueue(told("bad", bad, 3))
	var output: Dictionary = executor.step(3, actor.snapshot())
	expect(has_status(output, "bad", "rejected") and executor.active_command_id() == "s", "invalid replacement preserves previous action")
	executor.step(4, actor.snapshot(), [{"command_id": "s", "phase": "staged"}])
	executor.enqueue(told("old_cue", message("old_cue", "cue", {"command_id": "s"}, 1, 20), 5))
	expect(has_status(executor.step(5, actor.snapshot()), "old_cue", "rejected", "not_ready"), "cue issued before ready cannot release later")
	# Flash availability can change between acceptance and the go cue.
	executor = make_executor()
	var armed_flash = flash("armed_flash")
	armed_flash.payload.timing.mode = "on_cue"
	executor.enqueue(told("arm_flash", armed_flash))
	executor.step(2, actor.snapshot())
	executor.step(3, actor.snapshot(), [{"command_id": "armed_flash", "phase": "staged"}])
	actor.flash_count = 0
	executor.enqueue(told("cue", message("cue", "cue", {"command_id": "armed_flash"}, 3, 20), 4))
	output = executor.step(4, actor.snapshot())
	expect(has_status(output, "armed_flash", "failed", "no_utility") and has_status(output, "cue", "rejected", "no_utility"), "cue does not claim success when launch fails")
	expect(output.intents.size() == 1 and output.intents[0].op == "stop", "failed flash never dispatched")
	actor.flash_count = 1
	executor = make_executor()
	executor.enqueue(told("f", flash()))
	executor.step(2, actor.snapshot())
	executor.enqueue(told("cancel", message("cancel", "cancel", {"command_id": "f1"}), 3))
	expect(has_status(executor.step(3, actor.snapshot()), "cancel", "rejected", "busy_committed"), "committed throw cannot be cancelled")
	executor = make_executor()
	var report = message("report", "report", {"action": "report_enemy", "region_id": "logs", "count": null, "hedge": "unsure"})
	executor.enqueue(told("r1", report))
	expect(executor.step(2, actor.snapshot()).reports.size() == 1, "first report forwarded")
	executor.enqueue(told("r2", report, 3))
	expect(executor.step(3, actor.snapshot()).reports.is_empty(), "retransmitted report cannot update belief twice")
	executor = make_executor()
	executor.enqueue(told("s", swing()))
	executor.step(2, actor.snapshot())
	executor.step(3, actor.snapshot(), [{"command_id": "s1", "phase": "staged"}])
	executor.enqueue(observation("wrong_player", {"type": "player_entry", "actor_id": "other", "entry_id": "entry"}, 4, "seen", 3))
	expect(executor.step(4, actor.snapshot()).intents.is_empty(), "other actor motion cannot release a swing")
	executor.enqueue(observation("stale_motion", {"type": "player_entry", "actor_id": "player", "entry_id": "entry"}, 5, "seen", 1))
	expect(executor.step(5, actor.snapshot()).intents.is_empty(), "movement from before ready is not a new go signal")
	for discriminator in ["enemy_seen", "sound_heard", "", 7, null]:
		executor.enqueue(observation("wrong_event:" + str(discriminator), {"type": discriminator, "actor_id": "player", "entry_id": "entry"}, executor.inbox.current_tick() + 1, "seen", 5))
		expect(executor.step(executor.inbox.current_tick() + 1, actor.snapshot()).intents.is_empty(), "non-entry event cannot release coordinated swing: " + str(discriminator))
	var release_tick: int = executor.inbox.current_tick() + 2
	executor.enqueue(observation("valid_entry", {"type": "player_entry", "actor_id": "player", "entry_id": "entry"}, release_tick, "seen", release_tick - 1))
	expect(executor.step(release_tick - 1, actor.snapshot()).intents.is_empty(), "entry release respects actual observation delay")
	output = executor.step(release_tick, actor.snapshot())
	expect(output.intents.size() == 1 and output.intents[0].op == "start_swing" and "valid_entry" in output.intents[0].evidence_ids, "valid delivered entry releases once with its evidence")
	var ordered = Inbox.new("ally")
	ordered.enqueue(observation("a_later", {}, 9, "seen", 8))
	ordered.enqueue(observation("z_earlier", {}, 9, "seen", 3))
	expect(ordered.release(9)[0].id == "z_earlier", "equal delivery times retain event chronology")
	var bad_number = told("nan", swing())
	bad_number.content.message.issued_tick = NAN
	expect(not ordered.enqueue(bad_number).ok, "NaN cannot cross observation boundary")
	executor = make_executor()
	executor.enqueue(told("flash_pending", flash()))
	output = executor.step(2, actor.snapshot(), [{"command_id": "x", "phase": "invented"}])
	expect(output.errors == ["invalid_feedback"] and output.intents.is_empty(), "malformed feedback fails atomically before dispatch")
	expect(has_status(executor.step(2, actor.snapshot()), "f1", "executing"), "valid retry after input error retains queued message")

func test_review_regressions() -> void:
	var actor = FakeActor.new()
	var inbox = Inbox.new("ally")
	var foreign_type = told("foreign_type", swing())
	foreign_type.bot_id = 1
	expect(inbox.enqueue(foreign_type).get("ok") == false, "wrong-type bot ID rejected without runtime error")
	var executor = make_executor()
	executor.enqueue(observation("a_bad_type", {"type": 1}))
	executor.enqueue(told("z_good", swing()))
	var output: Dictionary = executor.step(2, actor.snapshot())
	expect(has_status(output, "s1", "accepted"), "malformed content discriminator cannot drop valid delivery batch")
	executor = make_executor()
	var wrong_version = swing()
	wrong_version.schema_version = 1
	executor.enqueue(told("wrong_version", wrong_version))
	expect(has_status(executor.step(2, actor.snapshot()), "s1", "rejected", "invalid_message"), "wrong-type schema constant rejected without runtime error")
	executor = make_executor()
	executor.enqueue(told("now", swing("now", "now")))
	executor.step(2, actor.snapshot())
	output = executor.step(3, actor.snapshot(), [{"command_id": "now", "phase": "staged"}, {"command_id": "now", "phase": "completed"}])
	expect(output.get("errors") == ["invalid_feedback"] and output.get("intents", []).is_empty(), "multiple feedback phases for same command rejected atomically")
	output = executor.step(3, actor.snapshot(), [{"command_id": "now", "phase": "staged"}])
	expect(has_status(output, "now", "executing") and not has_status(output, "now", "completed"), "start intent must dispatch before action can complete")
	output = executor.step(13, actor.snapshot())
	expect(has_status(output, "now", "failed", "execution_failed") and output.intents[0].op == "stop", "swing execution uses configured timeout")

func test_wrong_type_matrix() -> void:
	var validator = Validator.new(schema)
	for key in ["schema_version", "message_id", "speaker_id", "recipient_id", "kind"]:
		for wrong in [null, true, 1, [], {}]:
			var candidate = swing()
			candidate[key] = wrong
			expect(not validator.valid(candidate), "reject wrong type for " + key)
	for key in ["action", "target_id", "timing"]:
		for wrong in [null, true, 1, [], {}]:
			var candidate = swing()
			candidate.payload[key] = wrong
			expect(not validator.valid(candidate), "reject wrong nested type for " + key)
	for key in ["id", "bot_id", "source", "speaker_id"]:
		for wrong in [null, true, 1, [], {}]:
			var candidate = told("wrong", swing())
			candidate[key] = wrong
			expect(Inbox.new("ally").enqueue(candidate).get("ok") == false, "reject malformed observation " + key)
	var actor = FakeActor.new()
	var executor = make_executor()
	executor.enqueue(told("s", swing()))
	executor.step(2, actor.snapshot())
	executor.step(3, actor.snapshot(), [{"command_id": "s1", "phase": "staged"}])
	executor.enqueue(observation("bad_motion", {"type": "player_entry", "actor_id": 7, "entry_id": []}, 4, "seen", 3))
	expect(executor.step(4, actor.snapshot()).intents.is_empty(), "malformed movement identities ignored safely")
