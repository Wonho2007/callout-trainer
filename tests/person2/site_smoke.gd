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
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/maps/b_site.json"))
	expect(scene.builder.map_data.walls == source.walls and source.walls.size() == 40, "uses all imported map walls without approximation replacement")
	expect(scene.builder.map_data.regions == source.regions and source.regions.size() == 7, "uses all seven imported zone definitions unchanged")
	expect(scene.builder.map_path == "res://world/maps/b_site.json", "plant scenario uses teammate map rather than old Lotus approximation")
	expect(scene.enemies.is_empty() and scene.builder.map_data.spawns.size() == 1, "unknown enemies have no actor or guessed spawn marker at plant")
	expect(scene.runtime._sensing._region(scene._player.global_position + Vector3.UP) == "b_heaven", "human starts in annotated Heaven region")
	expect(scene.runtime._sensing._region(scene.teammate.global_position + Vector3.UP) == "b_pit", "ally starts in Pit")
	expect(scene.runtime._sensing._region(scene._spike.global_position + Vector3.UP) == "b_pit", "scenario plant is in Pit instead of source authoring/debug spike location")
	expect(scene.runtime._sensing._region(Vector3(5.5, 1, -6)) == "b_upper", "Upper takes precedence over circular Pit overlap")
	expect(scene.runtime._sensing._region(Vector3(8.5, 1, 3.9)) == "", "outside-circle box corner is not falsely called Pit")
	expect(scene.builder.get_node("Regions/b_pit").get_child(0).shape is CylinderShape3D, "circular Pit has actual cylindrical region collision")
	var nav_ok: bool = true
	for marker in scene._scenario.motion_markers.values():
		var p: Array = marker.position
		var destination := Vector3(p[0], p[1], p[2])
		var path: PackedVector3Array = scene.builder.query_path(scene.teammate.global_position, destination)
		nav_ok = nav_ok and not path.is_empty() and path[0].distance_to(scene.teammate.global_position) < 0.75 and path[-1].distance_to(destination) < 0.75
	expect(nav_ok, "all seven authored bot anchors connect through real navigation")
	var utility_events: Array = []
	scene.utility.deployed.connect(func(ability: String, owner: String, _position: Vector3): utility_events.append([ability, owner]))
	while scene.scenario_tick < 380:
		await get_tree().physics_frame
	var cubby: Array = scene._scenario.motion_markers.b_cubby.position
	expect(scene.teammate.global_position.distance_to(Vector3(cubby[0], cubby[1], cubby[2])) < 0.5, "baseline physically traverses imported map from Pit to Cubby")
	expect(["smoke", "ally"] in utility_events, "first annotated smoke releases after physical staging on larger map")
	scene.scenario_tick = 1378
	await get_tree().physics_frame
	expect(scene.enemies.is_empty(), "no enemies before first-known +23 seconds")
	for _i in range(3):
		await get_tree().physics_frame
	expect(scene.enemies.size() == 4, "first-known arrivals materialize all four enemies on imported map")
	var valid_arrivals: bool = true
	for spec in scene._scenario.spawn_schedule:
		valid_arrivals = valid_arrivals and scene.runtime._sensing._region(scene.enemies[spec.actor_id].global_position + Vector3.UP) == spec.region_id
	expect(valid_arrivals, "every enemy arrives within its annotated region using new coordinates")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--site-capture="):
			await RenderingServer.frame_post_draw
			expect(get_viewport().get_texture().get_image().save_png(argument.trim_prefix("--site-capture=")) == OK, "rendered imported map capture saved")
	var victim: ActorBase = scene.enemies.crashies
	var bot: Node = scene.enemy_runtimes.crashies
	bot.enable_combat(scene.utility)
	scene._player.health.max_hp = 10000
	scene._player.health.reset()
	var flash: Node3D = scene.utility.throw_flash(victim.global_position + Vector3.UP * 1.6 - victim.global_basis.z, Vector3.ZERO)
	flash.freeze = true
	while is_instance_valid(flash) and not flash.is_active:
		flash.global_position = victim.global_position + Vector3.UP * 1.6 - victim.global_basis.z
		await get_tree().physics_frame
	for _i in range(3):
		await get_tree().physics_frame
	var until: int = bot.snapshot().own_perception.blind_until_tick
	expect(until > bot.current_tick() and scene._flash_indicators.crashies.visible, "real flash triggers enemy blackout and white head circle on new map")
	var rifle: Node = victim.get_node("TeammateRifle")
	var ammo: int = rifle.in_mag
	var safe: bool = true
	while bot.current_tick() < until - 1:
		await get_tree().physics_frame
		safe = safe and rifle.in_mag == ammo and bot.snapshot().combat.decision.get("action") != "engage"
	expect(safe, "flashed enemy cannot shoot throughout blackout on imported map")
	for _i in range(4):
		await get_tree().physics_frame
	expect(not scene._flash_indicators.crashies.visible, "flash circle expires normally on imported map")
	for actor in scene.enemies.values():
		actor.apply_damage(1000)
	await get_tree().physics_frame
	await get_tree().physics_frame
	expect(scene.enemies.values().all(func(actor: ActorBase): return not actor.visible and actor.collision_layer == 0), "dead enemies vanish with collision removed")
	expect(scene._round_state == "enemies_eliminated", "real deaths resolve plant hold on imported map")
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	expect(scene.enemies.is_empty() and scene.teammate.is_alive and scene.teammate.visible and scene.utility.active_smokes().is_empty(), "restart restores clean new-map baseline and removes old effects")
	expect(scene.runtime._sensing._region(scene._player.global_position + Vector3.UP) == "b_heaven", "restart preserves human's annotated Heaven start")
	print("PERSON2_SITE_", "FAIL" if failed else "PASS", " checks=", checks)
	get_tree().quit(1 if failed else 0)
