extends Node
var checks: int = 0
var failed: bool = false

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)

func run(scene: Node) -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene.enemies.is_empty() and scene.enemy_runtimes.is_empty() and scene._target == null, "plant starts with no guessed enemy actors/colliders")
	expect(scene.teammate.is_alive and scene._player.is_alive and scene._spike.time_left > 44, "two PRX actors and freshly planted spike at t0")
	expect(scene.builder.map_data.regions.size() == 7 and scene.builder.get_node("Regions").get_child_count() == 7, "seven named real Area3D regions")
	var pit := Vector3(-0.7, -0.5, 0.2)
	var heaven := Vector3(7.5, 1.6, -8)
	var path: PackedVector3Array = scene.builder.query_path(pit, heaven)
	expect(not path.is_empty() and path[0].distance_to(pit) < 0.8 and path[-1].distance_to(heaven) < 0.8, "pit to elevated Heaven connects through real navigation without distant snapping")
	expect(Array(path).any(func(p: Vector3): return p.y > 1.0), "navigation includes elevated platform")
	var original: Vector3 = scene._player.global_position
	scene._player.global_position = scene._spike.global_position
	Input.action_press("defuse")
	for _i in range(4):
		await get_tree().physics_frame
	Input.action_release("defuse")
	expect(scene._spike.defuse_progress == 0, "PRX player cannot defuse own plant")
	scene._player.global_position = original
	var tick: int = scene.runtime.current_tick() + 1
	var move: Dictionary = {"schema_version": "comms.v1", "message_id": "pit-to-heaven", "speaker_id": "player", "recipient_id": "ally",
		"issued_tick": tick, "expires_tick": tick + 600, "kind": "command", "payload": {"action": "swing_together", "target_id": "b_heaven", "timing": {"mode": "now"}}}
	expect(scene.runtime.submit_comm(move).ok, "authored Heaven route command accepted")
	var traversal: Dictionary = {"visited": false, "completed": false, "results": []}
	var authored_heaven: Array = scene._scenario.motion_markers.b_heaven.position
	var arrival := Vector3(authored_heaven[0], authored_heaven[1], authored_heaven[2])
	scene.runtime.comm_result.connect(func(result: Dictionary):
		traversal.results.append([result.status, result.reason_code])
		if result.message_id == "pit-to-heaven" and result.status == "completed":
			traversal.completed = true)
	while scene.runtime.current_tick() < tick + 280:
		if scene.teammate.global_position.y > 1.2 and scene.teammate.global_position.distance_to(arrival) < 0.5:
			traversal.visited = true
		await get_tree().physics_frame
	expect(traversal.visited and traversal.completed, "shared actor physically climbs from Pit to Heaven and reports completion")
	if not traversal.completed:
		print("LOTUS_TRAVERSAL_FAILURE ", traversal, " position=", scene.teammate.global_position)
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene.teammate.global_position.y < 0 and scene.enemies.is_empty(), "reset restores pit spawn before arrivals")
	# Fast-forward only the authored scenario clock: no scene truth is injected.
	scene.scenario_tick = 1378
	await get_tree().physics_frame
	expect(scene.enemies.is_empty(), "no enemies before +23s first-known position")
	await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene.enemies.size() == 4 and scene.enemy_runtimes.size() == 4, "all four first-known actors materialize at +23s")
	for spec in scene._scenario.spawn_schedule:
		var actor: ActorBase = scene.enemies[spec.actor_id]
		expect(actor.is_alive and actor.global_position.distance_to(Vector3(spec.position[0], spec.position[1], spec.position[2])) < 1.0, "first localized actor physically spawned: " + spec.actor_id)
	expect(scene.runtime._sensing._opponents.size() == 4, "late registration keeps actual sensing registry current")
	expect(scene.runtime.snapshot().observations.is_empty(), "registration itself does not deliver enemy testimony")
	var count: int = scene.enemies.size()
	for _i in range(6):
		await get_tree().physics_frame
	expect(scene.enemies.size() == count, "arrival schedule cannot duplicate actors")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lotus-capture="):
			await RenderingServer.frame_post_draw
			var image: Image = get_viewport().get_texture().get_image()
			expect(image.save_png(argument.trim_prefix("--lotus-capture=")) == OK, "rendered first-known arrivals capture saved")
	var policy = scene.RetakePolicy.new("retaker", "b_pit")
	var own: Dictionary = {"alive": true, "marker_id": "c_link", "reachable_marker_ids": ["a_link", "b_pit"]}
	var evidence: Dictionary = {"id": "seen", "bot_id": "retaker", "event_tick": 0, "available_tick": 12, "source": "seen", "content": {"type": "enemy_seen", "region_id": "b_heaven"}}
	expect(policy.decide(11, [evidence], own).target_id == "b_pit", "unavailable sight cannot activate reactive branch")
	var branch: Dictionary = policy.decide(12, [evidence], own)
	expect(branch.target_id == "a_link" and branch.evidence_ids == ["seen"], "authored branch cites actual delayed sight")
	var first = scene.SpawnSchedule.new(scene._scenario.spawn_schedule)
	expect(first.due(1379).is_empty() and first.due(1380).size() == 4 and first.due(1380).is_empty(), "schedule exact boundary and idempotence")
	var weapons: Array = []
	# Keep this weapon/elimination fixture alive long enough to test both paths;
	# normal play retains the source-derived 150/70 simplified health pools.
	scene._player.health.max_hp = 10000
	scene._player.health.reset()
	scene.teammate.health.max_hp = 10000
	scene.teammate.health.reset()
	for id in scene.enemy_runtimes:
		expect(scene.enemy_runtimes[id].enable_combat(scene.utility), "retaker uses shared rifle: " + id)
		weapons.append(scene.enemies[id].get_node("TeammateRifle"))
	for _i in range(75):
		await get_tree().physics_frame
	expect(weapons.any(func(weapon: Node): return weapon.in_mag < 25), "late retaker fires real shared weapon after delayed perception")
	for actor in scene.enemies.values():
		actor.apply_damage(1000)
	for _i in range(3):
		await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene._round_state == "enemies_eliminated", "real shared enemy deaths end the hold without forced source outcome")
	expect(scene._info_panel.text_for("Vision").contains("inactive"), "public elimination outcome stops sensing HUD")
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene.enemies.is_empty() and scene.enemy_runtimes.is_empty() and scene.scenario_tick < 5, "restart returns to plant with all unknown enemies absent")
	expect(scene.runtime.snapshot().observations.is_empty(), "restart clears late-spawn sensory memory")
	expect(scene._player.health.hp == 150 and scene.teammate.health.hp == 70, "reset restores source-derived health after guarded weapon fixture")
	print("PERSON2_LOTUS_", "FAIL" if failed else "PASS", " checks=", checks)
	get_tree().quit(1 if failed else 0)
