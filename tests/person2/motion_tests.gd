extends SceneTree
const Motion = preload("res://bots/motion_controller.gd")
const Actor = preload("res://tests/person2/motion_actor.gd")
const Navigation = preload("res://tests/person2/motion_navigation.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
var checks: int = 0
var failed: bool = false
var nodes: Array = []

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		printerr("FAIL: ", label)

func _initialize() -> void:
	call_deferred("run")

func setup(timeout: int = 3) -> Dictionary:
	var actor = Actor.new()
	var nav = Navigation.new()
	root.add_child(actor)
	root.add_child(nav)
	nodes.append_array([actor, nav])
	return {"actor": actor, "nav": nav, "inbox": Inbox.new("ally"),
		"motion": Motion.new("ally", actor, nav, markers(),
			{"entry": {"stage_marker_id": "home", "route_marker_ids": ["cover"]}}, 0.25, timeout)}

func markers() -> Dictionary:
	return {"home": {"position": [0, 0, 0], "watch_points": {"entrance": [0, 0, -5]}},
		"cover": {"position": [2, 0, 0], "watch_points": {"logs": [2, 0, 5]}}}

func plan(tick: int, target: String = "cover", evidence: Array = []) -> Dictionary:
	return {"ok": true, "decision": {"tick": tick, "bot_id": "ally", "goal": "reposition", "target_id": target,
		"watch_region_id": "logs" if target == "cover" else "entrance", "reason": "test", "evidence_ids": evidence}}

func step(d: Dictionary, tick: int, p: Dictionary = {}, intents: Array = [], active: Dictionary = {}) -> Dictionary:
	d.inbox.release(tick)
	return d.motion.step(tick, plan(tick) if p.is_empty() else p,
		{"errors": [], "intents": intents}, active, d.inbox)

func intent(tick: int, op: String, command: String = "swing") -> Dictionary:
	return {"bot_id": "ally", "command_id": command, "tick": tick, "op": op, "target_id": "entry", "evidence_ids": ["request"]}

func evidence(d: Dictionary) -> void:
	d.inbox.enqueue({"id": "request", "bot_id": "ally", "event_tick": 0, "available_tick": 1,
		"source": "told", "speaker_id": "player", "content": {"type": "fixture"}})

func run() -> void:
	var d = setup()
	expect(step(d, 0).state == "moving" and d.actor.move_dir.x > 0, "autonomy starts physical movement")
	d.actor.position = Vector3(2, 0, 0)
	expect(step(d, 1).state == "holding" and d.actor.move_dir == Vector3.ZERO, "actual arrival stops movement")
	expect(absf(angle_difference(d.actor.rotation.y, PI)) < 0.001, "arrival watches authored point")
	expect(d.motion.take_feedback().is_empty(), "autonomous arrival is not command completion")
	var again = d.motion.step(1, plan(1), {"errors": [], "intents": []}, {}, d.inbox)
	expect(not again.ok and d.actor.move_dir == Vector3.ZERO, "duplicate tick stops safely")
	for mode in ["empty", "partial", "offmesh", "nan"]:
		d = setup()
		d.nav.mode = mode
		expect(step(d, 0).state == "failed" and d.actor.move_dir == Vector3.ZERO, "reject physical path " + mode)
		d.nav.mode = "direct"
		expect(step(d, 1).state == "failed", "autonomous failure latches " + mode)
		d.motion.reset_fault()
		expect(step(d, 2).state == "moving", "explicit recovery restarts " + mode)
	d = setup()
	d.nav.navigation_is_ready = false
	expect(step(d, 0).reason == "navigation_not_ready", "no movement before synchronized navigation")
	d = setup()
	step(d, 0)
	expect(step(d, 3).reason == "stuck" and d.actor.move_dir == Vector3.ZERO, "no physical progress trips conservative stop")
	d = setup()
	step(d, 0)
	d.actor.is_alive = false
	expect(step(d, 1).reason == "actor_dead" and d.actor.move_dir == Vector3.ZERO, "death stops routine motion")
	d = setup()
	evidence(d)
	step(d, 0)
	var active: Dictionary = {"message_id": "swing"}
	expect(step(d, 1, {}, [intent(1, "stage")], active).state == "holding", "command overrides autonomy and stages at actual home")
	expect(d.actor.move_dir == Vector3.ZERO, "stage wins movement arbitration")
	expect(d.motion.take_feedback() == [{"command_id": "swing", "phase": "staged"}], "staged feedback only at arrival")
	expect(d.motion.take_feedback().is_empty(), "feedback is consumed once")
	step(d, 2, {}, [intent(2, "stage")], active)
	expect(d.motion.take_feedback().is_empty(), "repeated stage intent cannot emit readiness twice")
	var bad_plan: Dictionary = {"ok": false, "decision": {}}
	expect(step(d, 3, bad_plan, [intent(3, "start_swing")], active).state == "moving", "valid command works through planner error")
	var calls: int = d.actor.move_calls
	step(d, 4, bad_plan, [intent(4, "start_swing")], active)
	expect(d.actor.move_calls == calls + 1, "repeated dispatch does not restart or duplicate task")
	d.actor.position = Vector3(2, 0, 0)
	step(d, 5, bad_plan, [], active)
	expect(d.motion.take_feedback() == [{"command_id": "swing", "phase": "completed"}], "route completion uses actual arrival")
	step(d, 6, bad_plan, [], active)
	expect(d.motion.take_feedback().is_empty(), "route completion never emitted twice")
	expect(step(d, 7, {}, [intent(7, "stop")]).reason == "command_transition", "terminal command stop blocks autonomy for this tick")
	expect(step(d, 8, plan(8, "home")).state == "moving", "routine autonomy resumes on next plan")
	d = setup()
	evidence(d)
	step(d, 1, {}, [intent(1, "start_swing")], active)
	expect(not d.actor.move_dir.is_zero_approx(), "swing task moves")
	expect(step(d, 2, {}, [intent(2, "stop")]).state == "stopped" and d.actor.move_dir == Vector3.ZERO, "cancel or expiry immediately stops command movement")
	d = setup()
	evidence(d)
	expect(step(d, 1, {}, [intent(1, "start_swing"), intent(1, "stop")]).state == "stopped" and d.actor.move_calls == 0, "same-tick cancellation never dispatches abandoned action")
	d = setup()
	evidence(d)
	expect(step(d, 1, {}, [intent(1, "throw_flash")], active).reason == "utility_adapter_unavailable", "missing utility cannot claim a flash")
	expect(d.motion.take_feedback() == [{"command_id": "swing", "phase": "failed"}], "missing utility returns failure once")
	d = setup()
	evidence(d)
	step(d, 1, {}, [intent(1, "start_swing")], active)
	expect(step(d, 4, {}, [], active).reason == "stuck", "command route also fails on lack of progress")
	expect(d.motion.take_feedback() == [{"command_id": "swing", "phase": "failed"}], "physical command failure reaches executor")
	d = setup()
	evidence(d)
	var invalid: Dictionary = intent(1, "start_swing")
	invalid.evidence_ids = ["missing"]
	expect(not step(d, 1, {}, [intent(1, "stage"), invalid], active).ok and d.actor.move_calls == 0, "invalid batch has no partial physical dispatch")
	d = setup()
	step(d, 0)
	d.actor.position = Vector3(-0.2, 0, 0)
	step(d, 1)
	d.actor.position = Vector3.ZERO
	step(d, 2)
	d.actor.position = Vector3(-0.2, 0, 0)
	expect(step(d, 3).reason == "stuck", "oscillation without improved path distance cannot reset stuck timer")
	d = setup()
	expect(not step(d, 0, plan(0, "cover", ["request"])).ok and d.actor.move_calls == 0, "unavailable evidence cannot cause movement")
	evidence(d)
	expect(step(d, 1, plan(1, "cover", ["request"])).ok, "delivered evidence permits movement")
	var foreign: Dictionary = plan(2)
	foreign.decision.bot_id = "other"
	expect(not step(d, 2, foreign).ok and d.actor.move_dir == Vector3.ZERO, "foreign plan fails closed")
	d = setup()
	step(d, 0)
	var broken: Dictionary = plan(1)
	broken.decision.watch_region_id = "unknown"
	expect(not step(d, 1, broken).ok and d.actor.move_dir == Vector3.ZERO, "invalid watched angle stops old motion")
	d.inbox.release(2)
	expect(not d.motion.step(2, plan(2), {"errors": ["bad_feedback"], "intents": []}, {}, d.inbox).ok, "executor errors freeze physical controller")
	# Policy has no dependency on the privileged controller, scene or nav APIs.
	for policy in ["knowledge_planner.gd", "command_executor.gd"]:
		var code: String = FileAccess.get_file_as_string("res://bots/" + policy)
		for forbidden in ["motion_controller", "get_node(", "get_tree(", "global_position", "query_path", "ActorBase"]:
			expect(not code.contains(forbidden), policy + " forbidden dependency " + forbidden)
	for node in nodes:
		node.free()
	print("PERSON2_MOTION_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	quit(1 if failed else 0)
