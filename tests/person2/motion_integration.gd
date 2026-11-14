extends SceneTree
# Read-only copies of actual Person 1/3 sources in a disposable project.
# This is AUTOMATED engine integration, not a manual playtest/shared bootstrap.
const Actor = preload("res://actors/actor_base.gd")
const Builder = preload("res://world/sandbox_builder.gd")
const HealthComponent = preload("res://actors/health.gd")
const Belief = preload("res://belief/region_belief.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
const Motion = preload("res://bots/motion_controller.gd")
var checks: int = 0
var failed: bool = false
var tick: int = -1
var actor: CharacterBody3D
var room: Node3D
var executor: RefCounted
var beliefs: RefCounted
var planner: RefCounted
var motion: RefCounted
var hidden: Node3D
var launched: int = 0
var evidence_valid: bool = true
var results: Array = []
var last: Dictionary = {}
var regions: Array = ["region_a", "region_b", "region_mid"]

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		printerr("FAIL: ", label)

func _initialize() -> void:
	call_deferred("run")

func config() -> Dictionary:
	return {"regions": regions, "markers": [
		{"id": "home", "watch_regions": ["region_a"], "roles": ["hold"], "objectives": ["none"]},
		{"id": "cover", "watch_regions": ["region_b"], "roles": ["hold"], "objectives": ["none"]}],
		"baseline_marker_id": "home", "baseline_watch_region": "region_a", "threat_threshold": 0.55,
		"freshness_ticks": 1000, "heartbeat_ticks": 30, "switch_margin": 0.1}

func own() -> Dictionary:
	var marker: String = ""
	if actor.global_position.distance_to(Vector3(-5, 0, 7)) < 0.3:
		marker = "home"
	elif actor.global_position.distance_to(Vector3(5, 0, 7)) < 0.3:
		marker = "cover"
	return {"alive": actor.is_alive, "marker_id": marker, "reachable_marker_ids": ["home", "cover"], "role": "hold", "objective": "none"}

func message(id: String, kind: String, payload: Dictionary, delay: int = 1, lifetime: int = 500) -> void:
	var issued: int = tick + 1
	expect(executor.enqueue({"id": "obs:" + id, "bot_id": "ally", "event_tick": issued,
		"available_tick": issued + delay, "source": "told", "speaker_id": "player",
		"content": {"type": "comms", "message": {"schema_version": "comms.v1", "message_id": id,
			"speaker_id": "player", "recipient_id": "ally", "issued_tick": issued, "expires_tick": issued + lifetime,
			"kind": kind, "payload": payload}}}).ok, "enqueue " + id)

func cycle() -> Dictionary:
	await physics_frame
	tick += 1
	var physical: Dictionary = {"alive": actor.is_alive, "flash_count": 0, "reachable_target_ids": ["entry"]}
	var output: Dictionary = executor.step(tick, physical, motion.take_feedback())
	for report in output.reports:
		for record in executor.inbox.available():
			if record.id in report.evidence_ids:
				expect(beliefs.apply(record, tick).ok, "real Person 3 consumes accepted report")
	for intent in output.intents:
		if intent.op == "start_swing":
			launched += 1
	results.append_array(output.results)
	var plan: Dictionary = planner.decide(tick, beliefs.snapshot(), own(), executor.inbox, executor.active_command_snapshot())
	if not plan.ok:
		evidence_valid = false
	else:
		for id in plan.decision.evidence_ids:
			evidence_valid = evidence_valid and executor.inbox.evidence_available(id, tick)
	var status: Dictionary = motion.step(tick, plan, output, executor.active_command_snapshot(), executor.inbox)
	last = {"plan": plan, "motion": status, "executor": output}
	return last

func has_result(id: String, status: String) -> bool:
	for result in results:
		if result.message_id == id and result.status == status:
			return true
	return false

func run() -> void:
	room = Builder.new()
	room.build_on_ready = false
	root.add_child(room)
	# Person 1's current builder bakes at 0.2/0.1, but its project still uses
	# default map cells (0.25/0.25). Match ONLY this disposable test map before
	# building. Record the production mismatch as a Person 1 dependency.
	var navigation_map: RID = root.world_3d.navigation_map
	NavigationServer3D.map_set_cell_size(navigation_map, 0.2)
	NavigationServer3D.map_set_cell_height(navigation_map, 0.1)
	expect(room.build_from_file("res://world/maps/test_room.json") == OK, "actual Person 1 synthetic room builds")
	# Builder owns synchronization. Never force it ready or bypass the bake.
	await room.navigation_ready
	# The signal is emitted from a physics_frame continuation. Let the server
	# finish that frame before placing an actor/querying the newly baked map.
	await physics_frame
	await process_frame
	expect(room.navigation_is_ready, "actual generated navigation synchronized")
	actor = Actor.new()
	actor.name = "TestTeammate"
	actor.collision_layer = 4
	actor.collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	actor.add_child(shape)
	var health = HealthComponent.new()
	health.name = "Health"
	actor.add_child(health)
	root.add_child(actor)
	actor.position = Vector3(-5, 0, 7)
	hidden = Node3D.new()
	root.add_child(hidden)
	hidden.position = Vector3(7, 0, -7)
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	executor = Executor.new("ally", {"entries": ["entry"], "flashes": [], "regions": regions, "speakers": ["player"]}, schema, 500)
	beliefs = Belief.new("ally", regions, ["enemy"])
	planner = Planner.new("ally", config())
	motion = Motion.new("ally", actor, room, {
		"home": {"position": [-5, 0, 7], "watch_points": {"region_a": [-6, 0, -6]}},
		"cover": {"position": [5, 0, 7], "watch_points": {"region_b": [6, 0, 6]}}},
		{"entry": {"stage_marker_id": "home", "route_marker_ids": ["cover"]}})
	await cycle()
	expect(last.plan.decision.target_id == "home" and last.motion.state == "holding" and actor.move_dir.is_zero_approx(), "prior holds baseline in real room: " + str(last.motion))
	message("report", "report", {"action": "report_enemy", "region_id": "region_b", "count": 1, "hedge": "sure"}, 3)
	for i in range(3):
		await cycle()
	expect(last.plan.decision.target_id == "home", "report cannot affect goal/motion before available tick")
	await cycle()
	expect(last.plan.decision.target_id == "cover" and actor.move_dir.x > 0, "delivered report drives shared actor toward coverage: " + str(last.motion))
	expect(last.plan.decision.evidence_ids == ["obs:report"], "coverage cites actual delivered report")
	var start_position: Vector3 = actor.global_position
	for i in range(15):
		await cycle()
	expect(actor.global_position.x > start_position.x + 0.5, "shared CharacterBody3D actually moves under physics")
	# A real unseen scene node moves; neither policy nor controller sees it.
	var state: Dictionary = own()
	var first: Dictionary = Planner.new("ally", config()).decide(tick, beliefs.snapshot(), state, executor.inbox)
	hidden.position = Vector3(-8, 3, 8)
	var second: Dictionary = Planner.new("ally", config()).decide(tick, beliefs.snapshot(), state, executor.inbox)
	expect(first == second, "actual unseen-node perturbation leaves policy output identical")
	message("swing", "command", {"action": "swing_together", "target_id": "entry", "timing": {"mode": "now"}})
	await cycle()
	await cycle()
	expect(last.plan.decision.goal == "command" and actor.move_dir.x < 0, "command reverses routine coverage to authored staging")
	for i in range(240):
		await cycle()
		if has_result("swing", "completed"):
			break
	expect(has_result("swing", "ready") and has_result("swing", "executing") and has_result("swing", "completed"), "shared physical stage/route produces complete lifecycle")
	expect(launched == 1, "one accepted command dispatches exactly one physical swing")
	expect(actor.global_position.distance_to(Vector3(5, 0, 7)) < 0.35, "route completion requires real destination arrival")
	await cycle()
	expect(last.motion.state == "holding" and actor.move_dir.is_zero_approx(), "autonomy holds coverage after command completes")
	var expected_yaw: float = atan2(-(6 - actor.global_position.x), -(6 - actor.global_position.z))
	expect(absf(angle_difference(actor.rotation.y, expected_yaw)) < 0.01, "real actor watches authored reported-region angle")
	message("cancelled", "command", {"action": "swing_together", "target_id": "entry", "timing": {"mode": "on_cue"}})
	await cycle()
	await cycle()
	expect(actor.move_dir.x < 0, "second command stages without executing peek")
	message("cancel", "cancel", {"command_id": "cancelled"})
	await cycle()
	await cycle()
	expect(has_result("cancelled", "cancelled") and actor.move_dir.is_zero_approx(), "cancellation stops actual actor before routine resume")
	await cycle()
	expect(last.plan.decision.target_id == "cover", "autonomy resumes using still-fresh report")
	message("expires", "command", {"action": "swing_together", "target_id": "entry", "timing": {"mode": "on_cue"}}, 1, 4)
	for i in range(5):
		await cycle()
	expect(has_result("expires", "expired") and actor.move_dir.is_zero_approx(), "expiry stops physical staging")
	message("death", "command", {"action": "swing_together", "target_id": "entry", "timing": {"mode": "on_cue"}})
	await cycle()
	await cycle()
	actor.apply_damage(100)
	await cycle()
	expect(not actor.is_alive and has_result("death", "failed") and actor.move_dir.is_zero_approx(), "shared health death ends command and motion")
	expect(launched == 1, "cancelled/expired/dead commands never dispatch extra swing")
	expect(evidence_valid, "all generated decisions cite available bot-local evidence")
	room.free()
	actor.free()
	hidden.free()
	print("PERSON2_MOTION_INTEGRATION_" + ("FAIL" if failed else "PASS"), " checks=", checks, " physics_ticks=", tick + 1)
	quit(1 if failed else 0)
