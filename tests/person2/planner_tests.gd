extends SceneTree
const Planner = preload("res://bots/knowledge_planner.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
const Executor = preload("res://bots/command_executor.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	test_prior_and_reports()
	test_staleness_and_time()
	test_roles_and_reachability()
	test_command_priority()
	test_provenance()
	test_validation_and_copying()
	test_invariance_and_stability()
	test_hysteresis_and_malformed_evidence()
	test_current_map_peek_config()
	if failures.is_empty():
		print("PERSON2_PLANNER_PASS checks=", checks)
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func expect(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures.append("FAIL: " + name)

func test_current_map_peek_config() -> void:
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/b_site_coverage.json"))
	var state: Dictionary = {"alive": true, "marker_id": "home", "reachable_marker_ids": scenario.motion_markers.keys(), "role": "hold", "objective": "none"}
	var belief: Dictionary = {"bot_id": "ally", "tick": -1, "enemies": {"enemy": {"room": 0.3333333333333333, "entry": 0.3333333333333333, "corridor": 0.3333333333333333}}, "trust": {}, "evidence_ids": []}
	var inbox = Inbox.new("ally")
	inbox.release(0)
	var result: Dictionary = Planner.new("ally", scenario.planner).decide(0, belief, state, inbox)
	expect(result.ok and result.decision.target_id == "home", "current map accepts every physically reachable marker including lateral peek")
	state.marker_id = "peek_entry"
	expect(Planner.new("ally", scenario.planner).decide(0, belief, state, inbox).ok, "arriving at lateral peek cannot invalidate ordinary planner own state")

func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/synthetic_coverage.json")).planner

func own() -> Dictionary:
	return {"alive": true, "marker_id": "home", "reachable_marker_ids": ["home", "logs_cover", "defuse_cover"],
		"role": "hold", "objective": "none"}

func snapshot(probabilities: Dictionary = {}, evidence: Array = [], tick: int = -1) -> Dictionary:
	var distribution: Dictionary = {"entrance": 1.0 / 3.0, "logs": 1.0 / 3.0, "site": 1.0 / 3.0}
	if not probabilities.is_empty():
		distribution = probabilities
	return {"bot_id": "ally", "tick": tick, "enemies": {"enemy_1": distribution},
		"trust": {}, "evidence_ids": evidence}

func report(id: String = "r", event: int = 0, available: int = 2, region: String = "logs") -> Dictionary:
	return {"id": id, "bot_id": "ally", "event_tick": event, "available_tick": available, "source": "told", "speaker_id": "player",
		"content": {"type": "comms", "message": {"schema_version": "comms.v1", "message_id": "m_" + id,
		"speaker_id": "player", "recipient_id": "ally", "issued_tick": event, "expires_tick": 50,
		"kind": "report", "payload": {"action": "report_enemy", "region_id": region, "count": 1, "hedge": "sure"}}}}

func intel(prob: float = 0.8, event: int = 0, available: int = 2) -> Dictionary:
	var inbox = Inbox.new("ally")
	inbox.enqueue(report("r", event, available))
	inbox.release(available)
	return {"inbox": inbox, "belief": snapshot({"entrance": 1.0 - prob, "logs": prob, "site": 0.0}, ["r"], available)}

func test_prior_and_reports() -> void:
	var planner = Planner.new("ally", config())
	var inbox = Inbox.new("ally")
	inbox.release(0)
	var out: Dictionary = planner.decide(0, snapshot(), own(), inbox)
	expect(out.ok and out.decision.goal == "hold" and out.decision.target_id == "home", "uninformed prior holds baseline")
	expect(out.decision.evidence_ids.is_empty(), "prior does not invent evidence")
	var data = intel()
	out = Planner.new("ally", config()).decide(2, data.belief, own(), data.inbox)
	expect(out.ok and out.decision.goal == "reposition" and out.decision.target_id == "logs_cover", "report shifts coverage to authored cover")
	expect(out.decision.watch_region_id == "logs" and out.decision.evidence_ids == ["r"], "decision explains report evidence")
	var state = own()
	state.marker_id = "logs_cover"
	out = Planner.new("ally", config()).decide(2, data.belief, state, data.inbox)
	expect(out.decision.goal == "hold", "hold when already at useful cover")
	data = intel(0.5)
	out = Planner.new("ally", config()).decide(2, data.belief, own(), data.inbox)
	expect(out.decision.target_id == "home", "weak evidence does not force movement")

func test_staleness_and_time() -> void:
	var data = intel()
	var planner = Planner.new("ally", config())
	planner.decide(2, data.belief, own(), data.inbox)
	data.inbox.release(9)
	var out: Dictionary = planner.decide(9, data.belief, own(), data.inbox)
	expect(out.decision.target_id == "logs_cover", "fresh report remains usable")
	data.inbox.release(10)
	out = planner.decide(10, data.belief, own(), data.inbox)
	expect(out.decision.target_id == "home" and out.decision.reason == "stale_or_unsubstantiated_belief", "event-time expiry clears chase")
	expect(out.replanned, "age boundary triggers immediate replan")
	expect(not planner.decide(9, data.belief, own(), data.inbox).ok, "planner clock cannot rewind")
	# Prediction advances snapshot time without a new sighting/report.
	data.belief.tick = 10
	data.inbox.release(11)
	out = planner.decide(11, data.belief, own(), data.inbox)
	expect(out.decision.target_id == "home", "snapshot heartbeat cannot refresh old report")
	# A late delivery is aged from event time, not delivery time.
	data = intel(0.8, 0, 12)
	out = Planner.new("ally", config()).decide(12, data.belief, own(), data.inbox)
	expect(out.decision.target_id == "home", "late old report does not become fresh")

func test_roles_and_reachability() -> void:
	var data = intel()
	var state = own()
	state.role = "cover"
	state.objective = "defuse"
	var out: Dictionary = Planner.new("ally", config()).decide(2, data.belief, state, data.inbox)
	expect(out.decision.target_id == "defuse_cover", "role and defuse goal select appropriate coverage")
	state.marker_id = "defuse_cover"
	out = Planner.new("ally", config()).decide(2, data.belief, state, data.inbox)
	expect(out.decision.goal == "cover", "cover role maintains coverage when positioned")
	state = own()
	state.reachable_marker_ids = ["home"]
	out = Planner.new("ally", config()).decide(2, data.belief, state, data.inbox)
	expect(out.decision.target_id == "home", "unreachable alternative never selected")
	state.reachable_marker_ids = []
	state.marker_id = ""
	out = Planner.new("ally", config()).decide(2, data.belief, state, data.inbox)
	expect(out.decision.goal == "stop" and out.decision.target_id == null, "no reachable authored goal produces safe stop")
	state = own()
	state.alive = false
	out = Planner.new("ally", config()).decide(2, data.belief, state, data.inbox)
	expect(out.decision.goal == "stop" and out.decision.reason == "actor_dead", "dead actor does not plan movement")

func test_command_priority() -> void:
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	var executor = Executor.new("ally", {"entries": ["entry_a"], "flashes": ["flash_a"], "regions": ["logs"], "speakers": ["player"]}, schema)
	var msg: Dictionary = report().content.message.duplicate(true)
	msg.message_id = "swing"
	msg.kind = "command"
	msg.payload = {"action": "swing_together", "target_id": "entry_a", "timing": {"mode": "follow_player"}}
	var obs = report("cmd")
	obs.content.message = msg
	executor.enqueue(obs)
	executor.step(2, {"alive": true, "flash_count": 1, "reachable_target_ids": ["entry_a", "flash_a"]})
	var active: Dictionary = executor.active_command_snapshot()
	expect(active.message_id == "swing", "executor exposes copied active task")
	var out: Dictionary = Planner.new("ally", config()).decide(2, snapshot(), own(), executor.inbox, active)
	expect(out.ok and out.decision.goal == "command" and out.decision.target_id == "entry_a", "accepted player command takes priority")
	expect(out.decision.evidence_ids == ["cmd"], "command priority cites actual accepted request")
	active.target_id = "tampered"
	expect(executor.active_command_snapshot().target_id == "entry_a", "active snapshot cannot mutate executor")
	var forged = executor.active_command_snapshot()
	forged.message_id = "invented"
	expect(not Planner.new("ally", config()).decide(2, snapshot(), own(), executor.inbox, forged).ok, "forged command without matching evidence rejected")

func test_provenance() -> void:
	var data = intel()
	var bad = data.belief.duplicate(true)
	bad.bot_id = "foreign"
	expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "foreign belief rejected")
	bad = data.belief.duplicate(true)
	bad.tick = 3
	expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "future snapshot rejected")
	bad = data.belief.duplicate(true)
	bad.evidence_ids = ["fabricated"]
	expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "fabricated evidence rejected")
	var foreign_inbox = Inbox.new("other")
	foreign_inbox.release(2)
	expect(not Planner.new("ally", config()).decide(2, data.belief, own(), foreign_inbox).ok, "foreign inbox rejected")
	var late = Inbox.new("ally")
	late.release(5)
	late.enqueue(report())
	late.release(6)
	expect(not Planner.new("ally", config()).decide(6, data.belief, own(), late).ok, "snapshot cannot claim evidence delivered after its timestamp")
	var inbox = Inbox.new("ally")
	inbox.enqueue(report())
	inbox.release(1)
	expect(not Planner.new("ally", config()).decide(2, data.belief, own(), inbox).ok, "inbox must be released through decision tick")
	bad = data.belief.duplicate(true)
	bad.evidence_ids = ["r", "r"]
	expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "duplicate evidence rejected")

func test_validation_and_copying() -> void:
	var data = intel()
	for invalid in [-0.1, 1.2, NAN, "0.8", true, null]:
		var bad = data.belief.duplicate(true)
		bad.enemies.enemy_1.logs = invalid
		expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "invalid probability fails closed")
	var bad = data.belief.duplicate(true)
	bad.enemies.enemy_1.site = 0.4
	expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "unnormalized belief rejected")
	bad = data.belief.duplicate(true)
	bad["hidden_enemy_position"] = [1, 2, 3]
	expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "no hidden fields accepted")
	var state = own()
	state["world"] = {}
	expect(not Planner.new("ally", config()).decide(2, data.belief, state, data.inbox).ok, "own state cannot smuggle world")
	var cfg = config()
	var planner = Planner.new("ally", cfg)
	cfg.markers.clear()
	var out: Dictionary = planner.decide(2, data.belief, own(), data.inbox)
	expect(out.ok, "planner copies static configuration")
	out.decision.evidence_ids.clear()
	data.inbox.release(3)
	expect(planner.decide(3, data.belief, own(), data.inbox).decision.evidence_ids == ["r"], "returned decision cannot mutate cache")
	var bad_config = config()
	bad_config.markers[1].id = "home"
	expect(not Planner.new("ally", bad_config).decide(2, data.belief, own(), data.inbox).ok, "duplicate markers rejected")
	bad_config = config()
	bad_config.threat_threshold = 2
	expect(not Planner.new("ally", bad_config).decide(2, data.belief, own(), data.inbox).ok, "invalid tuning rejected")

func test_invariance_and_stability() -> void:
	var data = intel()
	var a: Dictionary = Planner.new("ally", config()).decide(2, data.belief, own(), data.inbox)
	var privileged_world = {"hidden_enemy": [100, 0, 100]}
	privileged_world.hidden_enemy = [-100, 0, -100]
	var b: Dictionary = Planner.new("ally", config()).decide(2, data.belief, own(), data.inbox)
	expect(a == b, "unseen enemy perturbation leaves decision unchanged")
	var planner = Planner.new("ally", config())
	planner.decide(2, data.belief, own(), data.inbox)
	data.inbox.release(3)
	expect(not planner.decide(3, data.belief, own(), data.inbox).replanned, "unchanged inputs use heartbeat cache")
	data.inbox.release(5)
	expect(planner.decide(5, data.belief, own(), data.inbox).replanned, "heartbeat performs bounded reconsideration")
	var code = FileAccess.get_file_as_string("res://bots/knowledge_planner.gd")
	for forbidden in ["get_node(", "get_tree(", "global_position", "FileAccess", "Callable", "SceneTree"]:
		expect(not code.contains(forbidden), "planner dependency restriction " + forbidden)

func test_hysteresis_and_malformed_evidence() -> void:
	var cfg = config()
	cfg.threat_threshold = 0.35
	var planner = Planner.new("ally", cfg)
	var inbox = Inbox.new("ally")
	inbox.enqueue(report("logs", 0, 2, "logs"))
	inbox.enqueue(report("entrance", 0, 2, "entrance"))
	inbox.release(2)
	var belief = snapshot({"entrance": 0.45, "logs": 0.55, "site": 0.0}, ["logs", "entrance"], 2)
	var out: Dictionary = planner.decide(2, belief, own(), inbox)
	expect(out.decision.target_id == "logs_cover", "initial stronger coverage selected")
	inbox.release(3)
	belief.enemies.enemy_1 = {"entrance": 0.52, "logs": 0.48, "site": 0.0}
	belief.tick = 3
	out = planner.decide(3, belief, own(), inbox)
	expect(out.decision.target_id == "logs_cover", "small score change does not oscillate goals")
	inbox.release(4)
	belief.enemies.enemy_1 = {"entrance": 0.70, "logs": 0.30, "site": 0.0}
	belief.tick = 4
	out = planner.decide(4, belief, own(), inbox)
	expect(out.decision.target_id == "home", "meaningful evidence change overrides hysteresis")
	var reverse_cfg = config()
	reverse_cfg.markers.reverse()
	var data = intel()
	var state = own()
	state.reachable_marker_ids.reverse()
	var first: Dictionary = Planner.new("ally", config()).decide(2, data.belief, own(), data.inbox)
	var second: Dictionary = Planner.new("ally", reverse_cfg).decide(2, data.belief, state, data.inbox)
	expect(first.decision == second.decision, "marker iteration order cannot change chosen action")
	for wrong in [null, true, 1, [], {}]:
		var bad = data.belief.duplicate(true)
		bad.bot_id = wrong
		expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "malformed bot ID rejected")
		bad = data.belief.duplicate(true)
		bad.tick = wrong
		if not (wrong is int and wrong == 1):
			expect(not Planner.new("ally", config()).decide(2, bad, own(), data.inbox).ok, "malformed tick rejected")
		var bad_state = own()
		bad_state.role = wrong
		expect(not Planner.new("ally", config()).decide(2, data.belief, bad_state, data.inbox).ok, "malformed role rejected")
	# Unrelated or negative evidence must not refresh positive threat support.
	var old = intel()
	old.inbox.enqueue({"id": "clear", "bot_id": "ally", "event_tick": 11, "available_tick": 12,
		"source": "seen", "speaker_id": "sensor", "content": {"type": "region_clear", "region_id": "site", "coverage": "complete"}})
	old.inbox.release(12)
	old.belief.tick = 12
	old.belief.evidence_ids.append("clear")
	expect(Planner.new("ally", config()).decide(12, old.belief, own(), old.inbox).decision.target_id == "home", "new negative evidence cannot refresh an old enemy report")
	# Nonsemantic input must not trigger Variant comparison errors.
	var malformed_inbox = Inbox.new("ally")
	malformed_inbox.enqueue({"id": "weird", "bot_id": "ally", "event_tick": 0, "available_tick": 2,
		"source": "seen", "speaker_id": "sensor", "content": {"type": "enemy_seen", "enemy_id": [], "region_id": {}}})
	malformed_inbox.release(2)
	expect(Planner.new("ally", config()).decide(2, snapshot({"entrance": 0.2, "logs": 0.8, "site": 0.0}, ["weird"], 2), own(), malformed_inbox).ok, "malformed unsupported sensory payload ignored without engine error")
	old.inbox.enqueue(report("fresh_but_weak", 11, 12, "entrance"))
	old.inbox.release(12)
	old.belief.evidence_ids.append("fresh_but_weak")
	expect(Planner.new("ally", config()).decide(12, old.belief, own(), old.inbox).decision.reason == "stale_or_unsubstantiated_belief", "fresh weak report cannot disguise stale high-mass information")
