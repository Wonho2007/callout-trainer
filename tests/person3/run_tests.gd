extends SceneTree
const Model = preload("res://belief/region_belief.gd")
const Reports = preload("res://comms/report_adapter.gd")
const Audit = preload("res://recording/evidence_audit.gd")
const Metrics = preload("res://grading/belief_metrics.gd")
const Replay = preload("res://belief/replay.gd")
var failures: Array = []
var assertions: int = 0

func check(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: " + label)

func model() -> RefCounted:
	return Model.new("ally_1", ["entry", "site", "upper"], ["enemy_1"])

func report(id: String = "call_1", region: String = "upper", issued: int = 120, due: int = 138) -> Dictionary:
	return Reports.told_observation(Reports.make_report(id, "player", "ally_1", issued, issued + 100, region), "obs_" + id, due)

func seen(region: String, event: int, due: int, id: String = "seen_1") -> Dictionary:
	return {"id": id, "bot_id": "ally_1", "event_tick": event, "available_tick": due,
		"source": "seen", "speaker_id": "ally_1",
		"content": {"type": "enemy_seen", "enemy_id": "enemy_1", "region_id": region}}

func clear_region(event: int, due: int) -> Dictionary:
	var observation: Dictionary = seen("upper", event, due, "clear_1")
	observation.content = {"type": "region_clear", "region_id": "upper", "coverage": "complete"}
	return observation

func _initialize() -> void:
	var belief: RefCounted = model()
	var observation: Dictionary = report()
	check(not belief.apply(observation, 137).ok, "reaction delay blocks early testimony")
	check(belief.snapshot().evidence_ids.is_empty(), "rejection leaves prior untouched")
	check(belief.apply(observation, 138).ok, "due testimony accepted")
	var snapshot: Dictionary = belief.snapshot()
	check(is_equal_approx(snapshot.enemies.enemy_1.upper, 0.933333), "sure report commits belief by hedge alone, not truth")
	check(snapshot.enemies.enemy_1.entry > 0.0, "testimony retains uncertainty")
	check(observation.content.message.payload.count == null, "unspecified count remains unknown")
	snapshot.enemies.enemy_1.upper = 0.0
	check(is_equal_approx(belief.snapshot().enemies.enemy_1.upper, 0.933333), "snapshots are deep copies")
	check(belief.apply(observation, 139).ok and belief.snapshot().evidence_ids.size() == 1, "observation redelivery idempotent")
	var duplicate: Dictionary = observation.duplicate(true)
	duplicate.id = "redelivery"
	check(belief.apply(duplicate, 139).ok and is_equal_approx(belief.snapshot().enemies.enemy_1.upper, 0.933333), "message redelivery cannot apply testimony twice")
	duplicate.content.message.payload.region_id = "site"
	duplicate.id = "conflict"
	check(not belief.apply(duplicate, 140).ok, "conflicting message ID rejected")
	check(not belief.apply(report("old", "site", 0, 1), 140).ok, "expired report rejected")
	check(not belief.apply(report("unknown", "invented", 140, 150), 150).ok, "unknown region rejected")
	var foreign: Dictionary = report()
	foreign.bot_id = "ally_2"
	check(not model().apply(foreign, 138).ok, "other bot evidence rejected")
	var hostile: Dictionary = report()
	hostile.content["node"] = Node.new()
	check(not model().apply(hostile, 138).ok, "engine object rejected at boundary")
	hostile.content.node.free()
	check(Reports.make_report("x", "player", "ally_1", 1, 1, "site").is_empty(), "invalid expiry rejected")
	check(Reports.make_report("x", "player", "ally_1", 1, 10, "site", 0).is_empty(), "zero count rejected")
	# Trust removed as a mechanism (DECISIONS.md 2026-11-14) and the vestigial empty
	# compatibility key is now dropped too. The snapshot must no longer carry `trust`;
	# Person 2's planner must drop it from keys_exact before this branch merges.
	check(not belief.snapshot().has("trust"), "trust field is no longer present in the snapshot")
	var sighting: RefCounted = model()
	sighting.apply(report(), 138)
	sighting.apply(seen("upper", 140, 155), 155)
	check(sighting.snapshot().enemies.enemy_1.upper > 0.933333, "a same-region sighting sharpens belief further")
	var moved: RefCounted = model()
	moved.apply(report(), 138)
	moved.apply(seen("site", 140, 155), 155)
	check(moved.snapshot().enemies.enemy_1.site > moved.snapshot().enemies.enemy_1.upper, "a later sighting elsewhere moves belief without any trust penalty")
	var cleared: RefCounted = model()
	cleared.apply(report(), 138)
	var before_clear: float = cleared.snapshot().enemies.enemy_1.upper
	cleared.apply(clear_region(120, 139), 139)
	check(cleared.snapshot().enemies.enemy_1.upper < before_clear, "complete coverage lowers belief in the cleared region")
	var partial: Dictionary = clear_region(120, 139)
	partial.content.coverage = "partial"
	check(not model().apply(partial, 139).ok, "partial visibility cannot clear a region")
	var transition: Dictionary = {
		"entry": {"entry": 0.5, "site": 0.5, "upper": 0.0},
		"site": {"entry": 0.0, "site": 0.5, "upper": 0.5},
		"upper": {"entry": 0.0, "site": 0.0, "upper": 1.0}}
	check(belief.predict(141, transition), "explicit static movement prediction")
	var probabilities: Dictionary = belief.snapshot().enemies.enemy_1
	check(is_equal_approx(probabilities.entry + probabilities.site + probabilities.upper, 1.0), "prediction stays normalized")
	transition.upper.upper = -1.0
	check(not belief.predict(142, transition), "invalid transition rejected")
	var noisy_identity: Dictionary = {
		"entry": {"entry": 1.000001, "site": 0.0, "upper": 0.0},
		"site": {"entry": 0.0, "site": 1.000001, "upper": 0.0},
		"upper": {"entry": 0.0, "site": 0.0, "upper": 1.000001}}
	var long_run: RefCounted = model()
	var predictions_ok: bool = true
	for tick in range(500):
		predictions_ok = long_run.predict(tick, noisy_identity) and predictions_ok
	var final_probabilities: Dictionary = long_run.snapshot().enemies.enemy_1
	check(predictions_ok and is_equal_approx(final_probabilities.entry + final_probabilities.site + final_probabilities.upper, 1.0), "prediction normalization prevents long-run floating point drift")
	var malformed: Dictionary = report("bad")
	malformed.content.message.payload["extra"] = "unsupported"
	check(not model().apply(malformed, 138).ok, "unknown report fields rejected")
	malformed = report("nan")
	malformed.content.message.payload.count = NAN
	check(not model().apply(malformed, 138).ok, "nonfinite values rejected")
	var isolated: RefCounted = model()
	var mutable_input: Dictionary = report("mutable")
	isolated.apply(mutable_input, 138)
	mutable_input.content.message.payload.region_id = "site"
	mutable_input.id = "mutated"
	check(is_equal_approx(isolated.snapshot().enemies.enemy_1.upper, 0.933333) and isolated.snapshot().evidence_ids == ["obs_mutable"], "caller mutation cannot alter applied evidence")
	var hedge: Dictionary = report("hedged")
	hedge.content.message.payload.hedge = "unsure"
	var hedged: RefCounted = model()
	hedged.apply(hedge, 138)
	check(is_equal_approx(hedged.snapshot().enemies.enemy_1.upper, 0.6), "the player's hedge is the only strength knob, no trust factor")
	check(not belief.apply(seen("site", 130, 135), 140).ok, "backwards time rejected")
	var decisions: Array = [{"bot_id": "ally_1", "tick": 138, "evidence_ids": [observation.id]}]
	check(Audit.check([observation], decisions).is_empty(), "valid evidence membership/time")
	decisions[0].tick = 137
	check(not Audit.check([observation], decisions).is_empty(), "audit catches early evidence")
	decisions[0].tick = 140
	decisions[0].bot_id = "ally_2"
	check(not Audit.check([observation], decisions).is_empty(), "audit catches foreign evidence")
	check(not Audit.check([observation, observation], []).is_empty(), "audit catches duplicate log IDs")
	check(not Audit.check([observation], [{"bot_id": "ally_1", "tick": 138, "evidence_ids": [observation.id, observation.id]}]).is_empty(), "audit catches duplicate decision evidence")
	var baseline: Dictionary = {"entry": 1.0 / 3, "site": 1.0 / 3, "upper": 1.0 / 3}
	var wrong: Dictionary = {"entry": 0.1, "site": 0.1, "upper": 0.8}
	check(Metrics.entropy(wrong) < Metrics.entropy(baseline) and Metrics.brier(wrong, "site") > Metrics.brier(baseline, "site"), "confident wrong call reduces entropy but worsens accuracy")
	check(Metrics.brier(wrong, "unknown") == null, "unavailable accuracy is null")
	var replay: Dictionary = Replay.run("ally_1", ["entry", "site", "upper"], ["enemy_1"], [seen("upper", 140, 155), report()])
	var ordered: Dictionary = Replay.run("ally_1", ["entry", "site", "upper"], ["enemy_1"], [report(), seen("upper", 140, 155)])
	check(replay.ok and replay == ordered, "fixed-log replay is deterministic and availability ordered")
	var tied_report: Dictionary = report("z_report", "upper", 120, 150)
	var tied_seen: Dictionary = seen("upper", 140, 150, "a_seen")
	var tied: Dictionary = Replay.run("ally_1", ["entry", "site", "upper"], ["enemy_1"], [tied_seen, tied_report])
	check(tied.ok and is_equal_approx(tied.final.enemies.enemy_1.upper, 0.999639), "equal availability orders deterministically like Person 2 inbox")
	var delayed_transport: Dictionary = report("transport")
	delayed_transport.event_tick = 125
	check(model().apply(delayed_transport, 138).ok, "trusted transport can deliver a previously issued message")
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://examples/person3_fake_run.json"))
	check(Audit.check(fixture.observations, fixture.decisions).is_empty(), "sanitized fake run audits")
	var fake_replay: Dictionary = Replay.run(fixture.bot_id, fixture.regions, fixture.enemy_ids, fixture.observations)
	check(fake_replay.ok, "sanitized fake run replays without world")
	var without_call: Dictionary = Replay.run(fixture.bot_id, fixture.regions, fixture.enemy_ids, [fixture.observations[1]])
	check(without_call.ok and without_call.final.enemies != fake_replay.final.enemies, "injected omitted call changes beliefs on fixed observations")
	if failures.is_empty():
		print("PERSON3_TESTS_PASS: %d assertions" % assertions)
		quit(0)
	else:
		quit(1)
