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
	# Optional actual-renderer preview, never inferred to be a human playtest.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--hud-capture="):
			camera.look_at(scene.teammate.global_position + Vector3.UP, Vector3.UP)
			await RenderingServer.frame_post_draw
			var path: String = argument.trim_prefix("--hud-capture=")
			expect(get_viewport().get_texture().get_image().save_png(path) == OK, "rendered HUD preview saved")
	await wait_ticks(runtime, 110)
	expect(panel.text_for("Vision") == "Vision: ready", "HUD blind countdown recovers with actual sensor status")
	# Buttons are wired to the same scene controls after releasing the mouse.
	var button_count: int = 0
	for button in panel.find_children("*", "Button", true, false):
		button_count += 1
		if button.text.begins_with("Enemy to entry"):
			button.pressed.emit()
	expect(button_count == 4 and enemy.global_position.distance_to(Vector3(0, 0, 9)) < 0.1, "mouse button callbacks place the same real enemy")
	scene._restart()
	while scene.get("_restart_pending"):
		await get_tree().physics_frame
	await get_tree().process_frame
	panel.update_information(scene.runtime.snapshot())
	expect(panel.text_for("Sight").contains("no enemy sighting") and panel.text_for("Vision") == "Vision: ready", "restart clears displayed old knowledge and blind status")
	print("PERSON2_HUD_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	get_tree().quit(1 if failed else 0)
