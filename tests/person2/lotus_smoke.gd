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
	expect(not InputMap.action_get_events("dash").any(func(event: InputEvent): return event is InputEventKey and event.physical_keycode == KEY_V), "V push-to-talk cannot also dash the player")
	expect(scene.builder.map_data.regions.size() == 7 and scene.builder.get_node("Regions").get_child_count() == 7, "seven named real Area3D regions")
	var pit := Vector3(-0.7, -0.5, 0.2)
	var heaven := Vector3(7.5, 1.6, -8)
	var path: PackedVector3Array = scene.builder.query_path(pit, heaven)
	expect(not path.is_empty() and path[0].distance_to(pit) < 0.8 and path[-1].distance_to(heaven) < 0.8, "pit to elevated Heaven connects through real navigation without distant snapping")
	expect(Array(path).any(func(p: Vector3): return p.y > 1.0), "navigation includes elevated platform")
	var utilities: Array = []
	scene.utility.deployed.connect(func(ability: String, owner: String, point: Vector3): utilities.append({"ability": ability, "owner": owner, "point": point}))
	while scene.scenario_tick < 245:
		await get_tree().physics_frame
	var cubby: Array = scene._scenario.motion_markers.b_cubby.position
	expect(scene.teammate.global_position.distance_to(Vector3(cubby[0], cubby[1], cubby[2])) < 0.5, "uninterrupted baseline physically moves ally into Cubby")
	expect(utilities.any(func(event: Dictionary): return event.ability == "smoke" and event.owner == "ally"), "baseline physically deploys first ally smoke")
	expect(not scene.runtime.scenario_snapshot().deviated, "no player evidence preserves baseline")
	scene.scenario_tick = 1138
	for _i in range(6):
		await get_tree().physics_frame
	expect(utilities.filter(func(event: Dictionary): return event.ability == "smoke" and event.owner == "ally").size() == 2, "recharged smoke physically deploys at +19s")
	expect(scene.enemies.is_empty() and utilities.any(func(event: Dictionary): return event.owner == "boaster"), "remote annotated smoke never materializes its unknown caster")
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene.utility.active_smokes().is_empty(), "restart clears old-round utility blockers")
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
	var victim: ActorBase = scene.enemies.crashies
	var victim_runtime: Node = scene.enemy_runtimes.crashies
	var flash: Node3D = scene.utility.throw_flash(victim.global_position + Vector3.UP * 1.6 - victim.global_basis.z * 1.0, Vector3.ZERO)
	flash.freeze = true
	while is_instance_valid(flash) and not flash.is_active:
		flash.global_position = victim.global_position + Vector3.UP * 1.6 - victim.global_basis.z * 1.0
		await get_tree().physics_frame
	for _i in range(3):
		await get_tree().physics_frame
	var until: int = victim_runtime.snapshot().own_perception.blind_until_tick
	expect(until > victim_runtime.current_tick(), "real flash blinds enemy through its own sensor")
	expect(scene._flash_indicators.crashies.visible, "white head circle is visible while enemy is flashbanged")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--lotus-capture="):
			scene._player.camera.global_position = victim.global_position + Vector3(0, 2.2, -3.5)
			scene._player.camera.look_at(victim.global_position + Vector3.UP * 1.3)
			await RenderingServer.frame_post_draw
			var capture: String = argument.trim_prefix("--lotus-capture=").get_basename() + "-flash.png"
			expect(get_viewport().get_texture().get_image().save_png(capture) == OK, "rendered flash indicator capture saved")
	var rifle: Node = victim.get_node("TeammateRifle")
	var magazine: int = rifle.in_mag
	var no_blind_shots: bool = true
	while victim_runtime.current_tick() < until - 1:
		await get_tree().physics_frame
		no_blind_shots = no_blind_shots and rifle.in_mag == magazine and victim_runtime.snapshot().combat.decision.get("action") != "engage"
	expect(no_blind_shots, "enemy never fires or engages throughout actual flash duration")
	for _i in range(4):
		await get_tree().physics_frame
	expect(not scene._flash_indicators.crashies.visible, "head circle disappears when flash expires")
	for actor in scene.enemies.values():
		actor.apply_damage(1000)
	for _i in range(3):
		await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene._round_state == "enemies_eliminated", "real shared enemy deaths end the hold without forced source outcome")
	expect(scene.enemies.values().all(func(actor: ActorBase): return not actor.visible and actor.collision_layer == 0 and actor.collision_mask == 0), "dead enemies disappear and stop blocking movement or shots")
	expect(scene._info_panel.text_for("Vision").contains("inactive"), "public elimination outcome stops sensing HUD")
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await get_tree().process_frame
	expect(scene.enemies.is_empty() and scene.enemy_runtimes.is_empty() and scene.scenario_tick < 5, "restart returns to plant with all unknown enemies absent")
	expect(scene.runtime.snapshot().observations.is_empty(), "restart clears late-spawn sensory memory")
	expect(scene._player.health.hp == 150 and scene.teammate.health.hp == 70, "reset restores source-derived health after guarded weapon fixture")
	scene.teammate.apply_damage(1000)
	await get_tree().physics_frame
	await get_tree().physics_frame
	expect(not scene.teammate.visible and scene.teammate.collision_layer == 0 and scene.teammate.collision_mask == 0, "dead teammate disappears without ending surviving player's control")
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	expect(scene.teammate.visible and scene.teammate.is_alive and scene.teammate.collision_layer != 0, "restart restores visible collidable living teammate")
	# A separate uninterrupted line verifies enemy utility without the earlier
	# deliberate Heaven deviation or combat fixture cancelling the throws.
	utilities.clear()
	var a_link: Array = scene._scenario.motion_markers.a_link.position
	scene._player.global_position = Vector3(a_link[0], a_link[1], a_link[2])
	scene.scenario_tick = 1378
	for _i in range(65):
		await get_tree().physics_frame
	expect(utilities.any(func(event: Dictionary): return event.owner == "crashies" and event.ability == "scan_orb"), "uninterrupted enemy baseline physically throws its Heaven recon orb")
	expect(scene.utility.recon_marks().is_empty(), "enemy recon never populates player minimap marks")
	var recon_sensor = scene.enemy_runtimes.crashies._sensing
	recon_sensor.scan_recon(scene._player.global_position + Vector3.UP * 1.5)
	expect(recon_sensor._pending_recon.any(func(observation: Dictionary): return observation.content.enemy_id == "player" and observation.available_tick >= observation.event_tick + 18 and not observation.content.has("aim_position")), "private recon creates delayed region-only sensor evidence")
	scene.scenario_tick = 1678
	for _i in range(110):
		await get_tree().physics_frame
	expect(utilities.any(func(event: Dictionary): return event.owner == "kaajak" and event.ability == "molly"), "uninterrupted Raze baseline physically releases and ignites its grenade adaptation")
	expect(scene.utility._mollies.size() == 1, "annotated one-use grenade cannot duplicate")
	expect(not scene.utility._mollies.is_empty() and scene.utility._mollies[0].global_position.distance_to(scene._spike.global_position) < 2.0, "physical grenade adaptation lands in Pit near the spike")
	recon_sensor.scan_recon(Vector3(a_link[0], 1.6, 14))
	expect(not recon_sensor._pending_recon.any(func(observation: Dictionary): return observation.content.enemy_id == "player"), "world wall prevents private recon testimony")
	var recon_smoke: Node3D = scene.utility.throw_smoke(scene._player.global_position)
	while not recon_smoke.is_active:
		await get_tree().physics_frame
	recon_sensor.scan_recon(scene._player.global_position + Vector3.UP * 1.5)
	expect(not recon_sensor._pending_recon.any(func(observation: Dictionary): return observation.content.enemy_id == "player"), "active smoke prevents private recon testimony")
	print("PERSON2_LOTUS_", "FAIL" if failed else "PASS", " checks=", checks)
	get_tree().quit(1 if failed else 0)
