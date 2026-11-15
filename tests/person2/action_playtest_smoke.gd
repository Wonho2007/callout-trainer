extends Node
# Automated synthetic input into the actual inherited FPS scene, not voice/LLM.
var checks: int = 0
var failed: bool = false

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		printerr("FAIL: ", label)

func ticks(scene: Node, count: int) -> void:
	var target: int = scene.runtime.current_tick() + count
	while scene.runtime.current_tick() < target:
		await get_tree().physics_frame

func wait_ready(scene: Node, deadline_ticks: int = 240) -> void:
	var deadline: int = scene.runtime.current_tick() + deadline_ticks
	while scene.runtime.current_tick() < deadline:
		if scene.runtime.snapshot().active_command.get("phase") == "ready":
			return
		await get_tree().physics_frame

func has_result(panel: Control, id: String, status: String, reason: String = "") -> bool:
	for result in panel.inspect().results:
		if result.message_id == id and result.status == status and (reason.is_empty() or result.reason_code == reason):
			return true
	return false

func run(scene: Node3D) -> void:
	var panel: Control = scene.action_panel
	await ticks(scene, 2)
	expect(get_viewport().get_visible_rect().encloses(panel.get_global_rect()), "developer panel is inside the actual viewport")
	expect(not panel.get_global_rect().intersects(scene.get("_info_panel").get_global_rect()), "action controls do not cover teammate information HUD")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--action-capture="):
			await RenderingServer.frame_post_draw
			expect(get_viewport().get_texture().get_image().save_png(argument.trim_prefix("--action-capture=")) == OK, "save actual first-person developer controls capture")
	expect(get_viewport().get_camera_3d() == scene.get("_player").camera, "action playtest keeps shared first-person camera")
	expect(scene.builder.map_data.id == "b_site_box", "action playtest inherits current map")
	expect(not panel.inspect().context.is_empty(), "harness receives copied policy context")
	expect(panel.inspect().record.has("physical"), "harness receives physical decision telemetry")
	var copied: Dictionary = panel.inspect()
	copied.context.clear()
	expect(not panel.inspect().context.is_empty(), "inspection cannot mutate captured context")
	expect(not panel.activate("repeat").ok and not panel.activate("cue").ok, "empty repeat and cue fail honestly")
	# Synthetic goals renew only from subsequent copied contexts, allowing long
	# travel while keeping the real 120-tick goal gate intact.
	expect(panel.activate("cover").ok, "cover fixture passes existing intent gate")
	await ticks(scene, 170)
	var cover := Vector3(-1, 0, 3)
	var home := Vector3(-2, 0, 11.5)
	expect(scene.teammate.global_position.distance_to(cover) < 0.4 and scene.runtime.snapshot().physical.state == "holding", "cover fixture reaches actual authored room marker")
	expect(panel.activate("home").ok, "home fixture passes existing intent gate")
	await ticks(scene, 170)
	expect(scene.teammate.global_position.distance_to(home) < 0.4, "home fixture physically repositions through shared navigation")
	expect(panel.activate("fallback").ok and panel.inspect().fixture_goal.is_empty(), "invalid goal fixture clears model control for fallback")
	await ticks(scene, 2)
	expect(panel.inspect().record.policy == "scripted_fallback", "fallback visible from actual decision record")
	var flash: Dictionary = panel.activate("flash")
	expect(flash.ok, "flash preparation enters delayed comm seam")
	await ticks(scene, 17)
	expect(scene.runtime.snapshot().active_command.is_empty(), "fixture commands cannot bypass delivery delay")
	await wait_ready(scene)
	expect(scene.runtime.snapshot().active_command.get("phase") == "ready", "flash readiness follows real staging")
	panel.activate("cancel")
	await ticks(scene, 23)
	expect(scene.runtime.snapshot().active_command.is_empty() and scene.runtime.snapshot().flash_count == 1, "cancelled preparation preserves physical inventory")
	var prepared: Dictionary = panel.activate("prepare")
	await wait_ready(scene)
	expect(has_result(panel, prepared.message_id, "ready"), "swing preparation exposes actual ready lifecycle")
	expect(scene.teammate.global_position.distance_to(home) < 0.4, "prepared swing stays at stage before cue")
	var cue: Dictionary = panel.activate("cue")
	expect(cue.ok, "go cue references copied active command")
	await ticks(scene, 170)
	expect(has_result(panel, prepared.message_id, "completed") and scene.teammate.global_position.distance_to(cover) < 0.4, "cue produces physical swing completion at route endpoint")
	var at_cover: Vector3 = scene.teammate.global_position
	expect(panel.activate("repeat").ok, "repeat resubmits identical comm ID")
	await ticks(scene, 23)
	expect(scene.runtime.snapshot().active_command.is_empty() and scene.teammate.global_position.distance_to(at_cover) < 0.3, "duplicate cue does not replay a swing")
	# Flash launch is the real shared physical action; actual blind effects stay
	# with the separate sensory suite, and are not forced here.
	flash = panel.activate("flash")
	await ticks(scene, 170)
	expect(scene.runtime.snapshot().active_command.get("phase") == "ready", "flash routes back to its authored launch marker")
	panel.activate("cue")
	await ticks(scene, 24)
	expect(has_result(panel, flash.message_id, "completed") and scene.runtime.snapshot().flash_count == 0, "real flash release completes and consumes one charge")
	panel.activate("repeat")
	await ticks(scene, 23)
	expect(scene.runtime.snapshot().flash_count == 0, "duplicate release cannot consume another charge")
	var empty: Dictionary = panel.activate("flash")
	await ticks(scene, 23)
	expect(has_result(panel, empty.message_id, "rejected", "no_utility"), "unavailable resource displays real rejection")
	var generation: int = panel.inspect().generation
	scene._restart()
	while scene.get("_restart_pending"):
		await get_tree().physics_frame
	await ticks(scene, 2)
	expect(panel.inspect().generation == generation + 1 and panel.inspect().last_comm.is_empty(), "restart rebinds fresh runtime and clears replay fixture")
	expect(scene.runtime.snapshot().flash_count == 1 and not panel.activate("repeat").ok, "reset restores inventory without replaying old command")
	# Exercise the real key callback and button callback, not a separate dispatch.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_1
	key.pressed = true
	panel._unhandled_key_input(key)
	await ticks(scene, 23)
	expect(panel.inspect().last_comm.get("kind") == "report" and not scene.runtime.snapshot().observations.is_empty(), "numeric shortcut delivers synthetic report through real delayed inbox")
	panel.get("_buttons").get("home").pressed.emit()
	expect(panel.inspect().fixture_goal == "home", "mouse button uses same validated goal path")
	print("PERSON2_ACTION_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	get_tree().quit(1 if failed else 0)
