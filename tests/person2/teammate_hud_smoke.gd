extends Node
var checks: int = 0
var failed: bool = false
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)
func wait_ticks(runtime: Node, count: int) -> void:
	var until: int = runtime.current_tick() + count
	while runtime.current_tick() < until:
		await get_tree().physics_frame
	await get_tree().process_frame
func key(code: int, down: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	return event
func capture_if_requested(camera: Camera3D, scene: Node3D, suffix: String) -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--hud-capture="):
			camera.look_at(scene.teammate.global_position + Vector3.UP, Vector3.UP)
			await RenderingServer.frame_post_draw
			var path: String = argument.trim_prefix("--hud-capture=")
			path = path.get_basename() + suffix + ".png"
			expect(get_viewport().get_texture().get_image().save_png(path) == OK, "rendered smoke HUD preview saved: " + suffix)
func run(scene: Node3D) -> void:
	var panel: PanelContainer = scene.get("_info_panel")
	var runtime: Node = scene.runtime
	var enemy: CharacterBody3D = scene.get("_target")
	await wait_ticks(runtime, 2)
	expect(panel.text_for("Sight").contains("no enemy sighting"), "HUD starts without hidden opponent information")
	# Exercise actual shortcut handlers rather than directly changing target pose.
	scene._unhandled_input(key(KEY_F6, true))
	expect(enemy.global_position.distance_to(Vector3(0, 0, 9)) < 0.1, "F6 safely places real enemy at authored visible entry")
	panel.update_information(runtime.snapshot())
	expect(panel.text_for("Sight").contains("no enemy sighting"), "enemy test placement cannot directly grant HUD knowledge")
	await wait_ticks(runtime, 8)
	expect(panel.text_for("Sight").contains("no enemy sighting"), "HUD waits for sensory reaction delay")
	await wait_ticks(runtime, 20)
	expect(panel.text_for("Sight").contains("enemy in entry"), "actual delayed sighting updates HUD with known enemy region")
	scene._unhandled_input(key(KEY_F7, true))
	expect(enemy.global_position.distance_to(Vector3(-4, 0, 3)) < 0.1, "F7 safely moves real enemy behind initial corridor wall")
	await wait_ticks(runtime, 45)
	expect(panel.text_for("Sight").contains("enemy in entry") and not panel.text_for("Sight").contains("in room"), "hidden enemy move leaves HUD last-seen memory in observed region")
	# A future envelope must not render even if a later UI caller supplies one.
	var state: Dictionary = runtime.snapshot()
	var received: int = state.observations.size()
	state.observations.append({"id": "future", "event_tick": state.tick, "available_tick": state.tick + 30,
		"source": "seen", "content": {"type": "enemy_seen", "enemy_id": "enemy", "region_id": "room"}})
	panel.update_information(state)
	expect(not panel.text_for("Sight").contains("in room"), "presentation ignores future observations defensively")
	expect(panel.text_for("Memory") == "Received updates: %d" % received, "HUD count excludes future observations too")
	# Place at actual first-person crosshair onto open corridor floor.
	var camera: Camera3D = scene.get("_player").camera
	var original: Transform3D = camera.global_transform
	camera.look_at(Vector3(-3, 0, 11.5), Vector3.UP)
	scene._unhandled_input(key(KEY_P, true))
	expect(Vector2(enemy.global_position.x + 3, enemy.global_position.z - 11.5).length() < 0.1, "P places enemy on real floor hit by the player camera ray")
	camera.global_transform = original
	var before: Vector3 = enemy.global_position
	expect(not scene._place_test_enemy(Vector3(-3.75, 0, 10)) and enemy.global_position == before, "placement rejects wall/off-navigation position without moving enemy")
	# Real Input state drives real ActorBase motion/collision and stops on release.
	Input.parse_input_event(key(KEY_RIGHT, true))
	await wait_ticks(runtime, 5)
	Input.parse_input_event(key(KEY_RIGHT, false))
	await wait_ticks(runtime, 2)
	expect(enemy.global_position.distance_to(before) > 0.1, "arrow key moves actual shared enemy actor")
	expect(enemy.move_dir.is_zero_approx(), "releasing arrow key stops test movement intent")
	scene._unhandled_input(key(KEY_F8, true))
	expect(not scene.utility.active_flashes().is_empty(), "F8 creates an actual shared flash effect")
	await wait_ticks(runtime, 40)
	expect(panel.text_for("Vision").contains("BLINDED"), "actual shared flash updates own blind countdown on HUD")
	expect(panel.text_for("Smoke").contains("unknown while blinded"), "HUD does not claim a new smoke view assessment while flashed")
	await wait_ticks(runtime, 110)
	expect(panel.text_for("Vision") == "Vision: ready", "HUD blind countdown recovers with actual sensor status")
	# Buttons are wired to the same scene controls after releasing the mouse.
	var button_count: int = 0
	for button in panel.find_children("*", "Button", true, false):
		button_count += 1
		if button.text.begins_with("Enemy to entry"):
			button.pressed.emit()
	expect(button_count == 4 and enemy.global_position.distance_to(Vector3(0, 0, 9)) < 0.1, "mouse button callbacks place the same real enemy")
	# Actual unattended FPS runtime + shared natural smoke, not synthetic HUD
	# flags. Shorten only this disposable project's ability duration.
	var definitions: Dictionary = scene.utility.get("_defs")
	var original_duration: float = float(definitions.smoke.duration_s)
	definitions.smoke.duration_s = 1.0
	scene.utility.throw_smoke(Vector3(0, 0, 8))
	await wait_ticks(runtime, 3)
	expect(panel.text_for("Smoke").contains("SMOKED OFF") and panel.text_for("Vision") == "Vision: restricted by smoke", "HUD marks the actual authored entry watch angle smoked off")
	await capture_if_requested(camera, scene, "-smoked-off")
	await wait_ticks(runtime, 70)
	scene.utility.throw_smoke(scene.teammate.global_position)
	await wait_ticks(runtime, 3)
	expect(panel.text_for("Smoke").contains("IN SMOKE") and panel.text_for("Vision") == "Vision: blocked by smoke", "HUD distinguishes teammate eyes physically inside shared smoke")
	await capture_if_requested(camera, scene, "")
	await wait_ticks(runtime, 70)
	expect(panel.text_for("Smoke") == "Smoke: clear on watched angle" and panel.text_for("Vision") == "Vision: ready", "normal FPS HUD clears smoke restriction after natural expiry")
	# The arch apron is physically visible but has no named region in this map.
	# A missing callout must not make an otherwise visible actor disappear.
	expect(scene._place_test_enemy(Vector3(1.5, 0, 5)), "can place enemy on the walkable unnamed arch apron")
	var sight_query := PhysicsRayQueryParameters3D.create(scene.teammate.global_position + Vector3.UP * 1.6, enemy.global_position + Vector3.UP * 1.6, 1)
	expect(scene.get_world_3d().direct_space_state.intersect_ray(sight_query).is_empty(), "unnamed-region regression has actual clear world LOS")
	await wait_ticks(runtime, 30)
	expect(panel.text_for("Sight").contains("unknown region"), "visible enemy in unnamed map space still reaches HUD after delay")
	var smoke_cutoff: int = runtime.current_tick() + 1
	scene.utility.throw_smoke(Vector3(0, 0, 8))
	await wait_ticks(runtime, 30)
	var blocked: bool = true
	for observation in runtime.snapshot().observations:
		if observation.content.get("type") == "enemy_seen_unknown_region":
			blocked = blocked and observation.event_tick < smoke_cutoff
	expect(blocked, "unknown-region sightings also stop updating through active smoke")
	await wait_ticks(runtime, 60)
	var refreshed: bool = false
	for observation in runtime.snapshot().observations:
		refreshed = refreshed or (observation.content.get("type") == "enemy_seen_unknown_region" and observation.event_tick >= smoke_cutoff)
	expect(refreshed and panel.text_for("Smoke") == "Smoke: clear on watched angle" and panel.text_for("Sight").contains("unknown region"), "unnamed-region sighting is freshly reacquired after real smoke expiry")
	definitions.smoke.duration_s = original_duration
	# Exercise the actual player's G controller path and real traveling wave.
	var shared_player: Node3D = scene.get("_player")
	camera.look_at(scene.teammate.global_position + Vector3.UP * 1.6, Vector3.UP)
	shared_player._unhandled_input(key(KEY_G, true))
	await wait_ticks(runtime, 15)
	var traveling_wave: Node3D = scene.utility.active_blind_waves()[-1]
	expect(not traveling_wave.is_active and panel.text_for("Vision").contains("BLINDED"), "actual G-cast traveling wave blinds teammate before endpoint detonation")
	var once_until: int = runtime.snapshot().own_perception.blind_until_tick
	await wait_ticks(runtime, 10)
	expect(runtime.snapshot().own_perception.blind_until_tick == once_until, "a passing wave does not continuously renew teammate blindness")
	shared_player._sample_passing_waves()
	expect(shared_player.get("_wave_blind_remaining") == 0.0, "caster behind the wave launch plane is not self-blinded at release")
	# The shared player's receiver obeys the same passing-wave primitive.
	var forward: Vector3 = -camera.global_basis.z
	var player_wave: Node3D = scene.utility.throw_blind_wave(camera.global_position + forward * 2, -forward)
	shared_player._sample_passing_waves()
	expect(not player_wave.is_active and shared_player.get("_wave_blind_remaining") > 0, "shared player is also blinded by a traveling incoming wave")
	var player_once: float = shared_player.get("_wave_blind_remaining")
	shared_player._sample_passing_waves()
	expect(shared_player.get("_wave_blind_remaining") == player_once, "shared player applies each passing wave only once")
	await wait_ticks(runtime, 160)
	# Own death stops sight even after the blind timer expires. Keep the player
	# alive so this exercises actor_dead separately from public round completion.
	var last_seen: String = panel.text_for("Sight")
	scene.teammate.health.apply_damage(scene.teammate.health.max_hp)
	await wait_ticks(runtime, 3)
	panel.update_information(runtime.snapshot())
	expect(panel.text_for("Vision").contains("inactive") and panel.text_for("Vision").contains("teammate down"), "dead teammate cannot advertise ready vision after blind recovery")
	expect(panel.text_for("Action") == "Action: teammate down" and panel.text_for("Smoke").contains("no live view"), "own death clearly disables live information status without ending surviving player's round")
	expect(panel.text_for("Sight").contains("unknown region") == last_seen.contains("unknown region"), "own death preserves last-seen memory rather than inventing new information")
	scene._restart()
	while scene.get("_restart_pending"):
		await get_tree().physics_frame
	await get_tree().process_frame
	panel.update_information(scene.runtime.snapshot())
	expect(panel.text_for("Sight").contains("no enemy sighting") and panel.text_for("Vision") == "Vision: ready", "restart clears displayed old knowledge and blind status")
	scene._on_spike_detonated()
	panel.update_information(scene.runtime.snapshot())
	expect(panel.text_for("Vision").contains("round ended") and panel.text_for("Action").contains("reset"), "ended round cannot misleadingly advertise live ready perception")
	print("PERSON2_HUD_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	get_tree().quit(1 if failed else 0)
