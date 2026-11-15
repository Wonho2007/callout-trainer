extends Node
var checks: int = 0
var failed: bool = false

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)

func run(scene: Node) -> void:
	if OS.get_cmdline_user_args().has("--position-orders-only"):
		await _test_player_position(scene)
		print("PERSON2_SITE_", "FAIL" if failed else "PASS", " checks=", checks, " scope=position_orders")
		get_tree().quit(1 if failed else 0)
		return
	await get_tree().physics_frame
	await get_tree().process_frame
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://world/maps/b_site.json"))
	expect(scene.builder.map_data.walls == source.walls, "uses all imported map walls without approximation replacement")
	var footprints_match: bool = source.regions.size() == 7
	for i in range(source.regions.size()):
		var actual: Dictionary = scene.builder.map_data.regions[i]
		var expected: Dictionary = source.regions[i]
		footprints_match = footprints_match and actual.id == expected.id and actual.center[0] == expected.center[0] and actual.center[2] == expected.center[2] and actual.size[0] == expected.size[0] and actual.size[2] == expected.size[2]
	expect(footprints_match, "keeps all seven source zone footprints; Pit volume extends to its deep floor")
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
	expect(until - bot.current_tick() >= 174 and victim.get_node("BlindIndicator").visible, "updated three-to-five-second flash drives native actor indicator and combat impairment")
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
	expect(scene.enemies.values().all(func(actor: ActorBase): return actor.get_children().all(func(child: Node): return not child is CollisionObject3D or child.collision_layer == 0)), "dead hitbox actors leave no child damage colliders blocking shots")
	expect(scene._round_state == "enemies_eliminated", "real deaths resolve plant hold on imported map")
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	expect(scene.enemies.is_empty() and scene.teammate.is_alive and scene.teammate.visible and scene.utility.active_smokes().is_empty(), "restart restores clean new-map baseline and removes old effects")
	expect(scene.runtime._sensing._region(scene._player.global_position + Vector3.UP) == "b_heaven", "restart preserves human's annotated Heaven start")
	await _test_flash_commands(scene)
	await _test_box_jumps(scene)
	print("PERSON2_SITE_", "FAIL" if failed else "PASS", " checks=", checks)
	get_tree().quit(1 if failed else 0)

func _test_player_position(scene: Node) -> void:
	await _reset(scene)
	var runtime: Node = scene.runtime
	var bridge: Node = scene.voice_bridge
	for phrase in ["play heaven with me", "come to B Heaven", "hold heaven", "let's play heaven together"]:
		expect(bridge._requested_position(phrase) == "b_heaven", "position call grounds to Heaven: " + phrase)
	for phrase in ["one enemy heaven", "flash heaven", "get ready to swing heaven", "don't play heaven", "play heaven or pit"]:
		expect(bridge._requested_position(phrase).is_empty(), "position guard preserves other/ambiguous comms: " + phrase)
	var packet: Dictionary = {"type": "proposal", "session": bridge.session, "id": "play-heaven",
		"transcript": "play heaven with me", "result": "clarify", "question": "Which action?"}
	bridge._receive(packet)
	var received: int = runtime.current_tick()
	expect(runtime.snapshot().player_goal.is_empty(), "position is not acted on before radio delivery")
	for _i in range(17): await get_tree().physics_frame
	expect(runtime.snapshot().player_goal.is_empty(), "position respects the existing 18-tick delay")
	var p: Array = scene._scenario.motion_markers.b_heaven.position
	var heaven := Vector3(p[0], p[1], p[2])
	var reached: bool = false
	for _i in range(500):
		await get_tree().physics_frame
		if scene.teammate.global_position.distance_to(heaven) < 0.4:
			reached = true
			break
	expect(reached, "play Heaven with me physically brings the teammate to Heaven")
	if not reached: print("PLAYER_POSITION_DIAGNOSTIC ", runtime.snapshot())
	# Enemy testimony can change beliefs/combat, but must not replace our position.
	runtime.submit_comm({"schema_version": "comms.v1", "message_id": "report-during-position",
		"speaker_id": "player", "recipient_id": "ally", "issued_tick": runtime.current_tick() + 1,
		"expires_tick": runtime.current_tick() + 601, "kind": "report",
		"payload": {"action": "report_enemy", "region_id": "b_pit", "count": 1, "hedge": "sure"}})
	for _i in range(660): await get_tree().physics_frame
	expect(runtime.current_tick() - received > 600 and runtime.snapshot().plan.decision.get("target_id") == "b_heaven", "player position outlives short command expiry and unrelated enemy reports")
	expect(scene.teammate.global_position.distance_to(heaven) < 0.5, "teammate holds Heaven instead of returning to spike")
	var goal: Dictionary = runtime.snapshot().player_goal
	expect(goal.evidence_ids.size() == 1 and runtime._executor.inbox.evidence_available(goal.evidence_ids[0], runtime.current_tick()), "persistent goal cites actually delivered own evidence")
	bridge._receive(packet)
	expect(runtime.snapshot().player_goal == goal, "transport retry cannot replace/replay a persistent order")
	expect(not runtime.submit_position_order("unknown").ok and runtime.snapshot().player_goal == goal, "unknown location cannot displace the accepted goal")
	bridge._receive({"type": "proposal", "session": bridge.session, "id": "prepare-before-position",
		"transcript": "get ready to swing heaven", "result": "command", "proposal": {"kind": "command",
		"payload": {"action": "swing_together", "target_id": "b_heaven", "timing": {"mode": "now"}}}})
	for _i in range(25): await get_tree().physics_frame
	# This entry's authored staging marker is Pit, not our current Heaven spot.
	# It should be staging (or ready if reached), never swing before the cue.
	expect(runtime.snapshot().active_command.get("phase") in ["accepted", "ready"] and runtime.snapshot().plan.decision.goal == "command", "temporary staged action still takes priority without swinging before cue")
	bridge._receive({"type": "proposal", "session": bridge.session, "id": "play-upper", "transcript": "play upper with me", "result": "clarify"})
	for _i in range(25): await get_tree().physics_frame
	expect(runtime.snapshot().player_goal.get("target_id") == "b_upper", "new positioning instruction replaces Heaven")
	expect(runtime.snapshot().active_command.is_empty(), "new position cancels a prepared swing through normal executor rules")
	bridge._receive({"type": "cancel", "session": bridge.session, "id": "cancel-position", "transcript": "cancel"})
	for _i in range(25): await get_tree().physics_frame
	expect(runtime.snapshot().player_goal.is_empty(), "cancel releases the persistent position even without an active swing")
	for i in range(12):
		runtime.submit_position_order("b_upper" if i == 11 else "b_heaven")
	for _i in range(25): await get_tree().physics_frame
	expect(runtime.snapshot().player_goal.get("target_id") == "b_upper", "latest same-tick order wins across numeric ID boundaries")
	runtime.submit_position_order("b_heaven")
	for _i in range(25): await get_tree().physics_frame
	await _reset(scene)
	expect(scene.runtime.snapshot().player_goal.is_empty(), "round restart clears persistent player intent")
	scene.voice_bridge._receive(packet)
	expect(scene.runtime.snapshot().player_goal.is_empty(), "old-session positioning packet cannot affect the new round")

func _test_box_jumps(scene: Node) -> void:
	await _reset(scene)
	expect(scene.builder.get_node("NavRegion").get_node_or_null("scenario_upper_access") == null, "added Upper ramp is removed")
	var results: Array = []
	scene.runtime.comm_result.connect(func(result: Dictionary): results.append(result))
	var issued: int = scene.runtime.current_tick() + 1
	scene.runtime.submit_comm({"schema_version": "comms.v1", "message_id": "jump-upper", "speaker_id": "player", "recipient_id": "ally",
		"issued_tick": issued, "expires_tick": issued + 600, "kind": "command", "payload": {"action": "swing_together", "target_id": "b_upper", "timing": {"mode": "now"}}})
	var on_box: bool = false
	var jumping: bool = false
	var states: Array = []
	for _i in range(580):
		var physical: Dictionary = scene.runtime.snapshot().physical
		if states.is_empty() or states[-1][0] != physical.get("reason"):
			states.append([physical.get("reason"), scene.teammate.global_position])
		var position: Vector3 = scene.teammate.global_position
		on_box = on_box or (scene.teammate.is_on_floor() and absf(position.y - 1.0) < 0.15 and absf(position.x - 12.405) < 0.5)
		jumping = jumping or scene.runtime.snapshot().physical.get("state") == "jumping"
		if results.any(func(result: Dictionary): return result.message_id == "jump-upper" and result.status in ["completed", "failed", "expired"]): break
		await get_tree().physics_frame
	var completed: bool = results.any(func(result: Dictionary): return result.message_id == "jump-upper" and result.status == "completed")
	expect(jumping and on_box, "teammate physically jumps and lands on existing box_3")
	expect(completed and scene.teammate.global_position.y > 1.9, "second physical jump reaches Upper and completes the command")
	if not completed: print("BOX_JUMP_DIAGNOSTIC ", scene.teammate.global_position, " states=", states, " results=", results)
	# After the completed player command, ordinary defensive autonomy returns
	# to Pit. This exercises descending jump links without inventing a command.
	var returned: bool = false
	for _i in range(580):
		if scene.teammate.is_on_floor() and scene.teammate.global_position.y < -2.8:
			returned = true
			break
		await get_tree().physics_frame
	expect(returned and scene.teammate.global_position.y < -2.8, "teammate can descend over the boxes and return to deep Pit")
	if not returned: print("BOX_DESCENT_DIAGNOSTIC ", scene.teammate.global_position, " physical=", scene.runtime.snapshot().physical, " results=", results)

func _flash_request(scene: Node, id: String, transcript: String, region: String = "c_link") -> void:
	# Deliberately model the wrong action/timing: explicit flash speech must
	# still map to a flash, not an accidental swing toward the target region.
	scene.voice_bridge._receive({"type": "proposal", "session": scene.voice_bridge.session,
		"id": id, "result": "command", "transcript": transcript, "proposal": {"kind": "command",
		"payload": {"action": "swing_together", "target_id": region, "timing": {"mode": "follow_player"}}}})

func _reset(scene: Node) -> void:
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await get_tree().physics_frame

func _flash_result_watch(scene: Node) -> Array:
	# Returns [releases, statuses] arrays updated by live signals until disconnected.
	var releases: Array = []
	var statuses: Array = []
	var cb_release := func(ability: String, _owner: String, point: Vector3):
		if ability == "flash": releases.append(point)
	var cb_result := func(result: Dictionary): statuses.append(result.status + "/" + result.reason_code)
	scene.utility.deployed.connect(cb_release)
	scene.runtime.comm_result.connect(cb_result)
	return [releases, statuses, cb_release, cb_result]

func _place_teammate(scene: Node, region: String) -> void:
	# Deterministically stand the teammate on an authored marker so the throw
	# geometry is fixed, independent of annotated-baseline timing.
	var p: Array = scene._scenario.motion_markers[region].position
	var marker := Marker3D.new()
	scene.add_child(marker)
	marker.global_position = Vector3(p[0], p[1], p[2])
	scene.teammate.teleport_to(marker)
	scene.teammate.set_move_dir(Vector3.ZERO)
	marker.free()
	await get_tree().physics_frame

func _test_far_zone_flash_walks(scene: Node) -> void:
	# Regression for the live playtest failure: "flash b heaven" issued while the
	# teammate stands at Cubby. From there every B Heaven aim point is occluded or
	# beyond the 20 m range, so the controller previously returned a terminal
	# "visible_zone_out_of_throw_range" and the command failed with
	# execution_failed WITHOUT moving. Required behavior is to walk toward the
	# zone and throw as soon as an in-range visible point opens.
	await _reset(scene)
	await _place_teammate(scene, "b_cubby")
	var watch: Array = _flash_result_watch(scene)
	var releases: Array = watch[0]
	var statuses: Array = watch[1]
	var start: Vector3 = scene.teammate.global_position
	var center_arr: Array = scene._scenario.motion_markers.b_heaven.position
	var center := Vector3(center_arr[0], center_arr[1], center_arr[2])
	_flash_request(scene, "far-b-heaven", "flash b heaven", "b_heaven")
	var walked: float = 0.0
	for _i in range(400):
		walked = maxf(walked, Vector2(scene.teammate.global_position.x - start.x, scene.teammate.global_position.z - start.z).length())
		if not releases.is_empty():
			break
		if scene.runtime.snapshot().active_command.is_empty() and _i > 25:
			break
		await get_tree().physics_frame
	expect(releases.size() == 1 and scene.runtime.snapshot().flash_count == 0, "far occluded B Heaven walks into range and throws instead of failing in place")
	expect("failed/execution_failed" not in statuses, "a far throwable zone does not report execution_failed without moving")
	expect(walked > 1.0, "the teammate physically repositions toward a zone it cannot yet throw")
	expect(scene.teammate.global_position.distance_to(center) > 2.5, "the teammate stops and throws before standing on the zone center")
	scene.utility.deployed.disconnect(watch[2])
	scene.runtime.comm_result.disconnect(watch[3])
	await _reset(scene)

func _test_flash_commands(scene: Node) -> void:
	await _test_far_zone_flash_walks(scene)
	# The new deep Pit correctly occludes C Link. Use an open C Link position
	# for the separate no-walking visibility case, not the obsolete flat Pit.
	await _place_teammate(scene, "c_link")
	var releases: Array = []
	scene.utility.deployed.connect(func(ability: String, _owner: String, point: Vector3):
		if ability == "flash": releases.append(point))
	expect(scene.runtime.snapshot().flash_count == 1, "teammate starts with the user-requested one flash per round")
	var start: Vector3 = scene.teammate.global_position
	var initial_yaw: float = scene.teammate.rotation.y
	var accepted: Dictionary = {"ready": false, "position": start, "yaw": initial_yaw}
	var capture_start := func(result: Dictionary):
		if result.status == "accepted":
			scene.teammate.rotation.y = PI
			accepted.ready = true
			accepted.position = scene.teammate.global_position
			accepted.yaw = PI
	scene.runtime.comm_result.connect(capture_start)
	_flash_request(scene, "visible-c-link", "flash c link")
	var movement: float = 0
	for _i in range(150):
		if accepted.ready:
			movement = maxf(movement, Vector2(scene.teammate.global_position.x - accepted.position.x, scene.teammate.global_position.z - accepted.position.z).length())
		if not releases.is_empty(): break
		await get_tree().physics_frame
	expect(scene.voice_bridge.events[-1].message.payload.action == "throw_flash", "flash utterance cannot become a swing command")
	expect(releases.size() == 1 and scene.runtime.snapshot().flash_count == 0, "flash C Link physically throws one shared projectile and consumes one charge")
	expect(movement < 0.15, "visible part of C Link is flashed without walking toward its center")
	expect(absf(angle_difference(accepted.yaw, scene.teammate.rotation.y)) > deg_to_rad(20), "teammate actually turns toward the flash destination")
	scene.runtime.comm_result.disconnect(capture_start)
	_flash_request(scene, "depleted-c-link", "flash c link")
	for _i in range(25): await get_tree().physics_frame
	expect(releases.size() == 1, "depleted flash inventory cannot create another projectile")
	await _reset(scene)
	releases.clear()
	# An actual active smoke blocks all zone rays while the bot is inside it.
	# Moving is permitted only after the turn confirms that occlusion.
	var smoke: Node3D = scene.utility.throw_smoke(scene.teammate.global_position)
	while not smoke.is_active: await get_tree().physics_frame
	start = scene.teammate.global_position
	_flash_request(scene, "occluded-c-link", "flash c link")
	var walked: bool = false
	var faced_first: bool = false
	var p: Array = scene._scenario.motion_markers.c_link.position
	var center := Vector3(p[0], p[1], p[2])
	for _i in range(150):
		var displacement: float = Vector2(scene.teammate.global_position.x - start.x, scene.teammate.global_position.z - start.z).length()
		if displacement > 0.05 and not walked:
			walked = true
			var heading: Vector3 = center - scene.teammate.global_position
			faced_first = absf(angle_difference(scene.teammate.rotation.y, atan2(-heading.x, -heading.z))) < deg_to_rad(5)
		if displacement > 0.8: break
		await get_tree().physics_frame
	expect(walked and faced_first, "occluded C Link is approached only after turning toward it")
	expect(releases.is_empty() and scene.runtime.snapshot().flash_count == 1, "blocked zone is not flashed blindly and inventory is retained")
	scene.voice_bridge._receive({"type": "cancel", "session": scene.voice_bridge.session, "id": "cancel-blocked-flash", "transcript": "cancel"})
	for _i in range(25): await get_tree().physics_frame
	expect(scene.runtime.snapshot().active_command.is_empty() and releases.is_empty() and scene.runtime.snapshot().flash_count == 1, "blocked flash can be cancelled without consuming a charge")
	_flash_request(scene, "retry-occluded-c-link", "flash c link")
	for _i in range(25): await get_tree().physics_frame
	smoke.is_active = false
	for _i in range(150):
		if not releases.is_empty(): break
		await get_tree().physics_frame
	expect(releases.size() == 1, "pending flash releases when a zone point becomes visible")
	expect(scene.teammate.global_position.distance_to(center) > 5, "bot stops seeking visibility and throws before walking all the way into C Link")
	await _reset(scene)
	releases.clear()
	_flash_request(scene, "cue-c-link", "flash c link on my cue")
	for _i in range(150):
		if scene.runtime.snapshot().active_command.get("phase") == "ready": break
		await get_tree().physics_frame
	expect(scene.runtime.snapshot().active_command.get("phase") == "ready" and releases.is_empty(), "on-cue flash prepares in place and waits")
	scene.voice_bridge._receive({"type": "cue", "session": scene.voice_bridge.session, "id": "flash-go", "transcript": "go"})
	for _i in range(65):
		if not releases.is_empty(): break
		await get_tree().physics_frame
	expect(releases.size() == 1, "separate cue releases a prepared visibility-first flash")
