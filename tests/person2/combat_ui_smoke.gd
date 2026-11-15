extends Node
var checks: int = 0
var failed: bool = false

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)

func capture(suffix: String) -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--combat-ui-capture="):
			await RenderingServer.frame_post_draw
			expect(get_viewport().get_texture().get_image().save_png(argument.trim_prefix("--combat-ui-capture=") + suffix + ".png") == OK, "rendered " + suffix)

func restart(scene: Node) -> void:
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await get_tree().process_frame

func arrive(scene: Node) -> void:
	scene.scenario_tick = 1378
	for _i in range(4):
		await get_tree().physics_frame

func run(scene: Node) -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	var ui: Control = scene._combat_feedback
	var player: ActorBase = scene._player
	var weapon: Node = player.get_node("Camera3D/Weapon")
	expect(scene.enemies.is_empty(), "UI does not spawn unknown enemies")
	expect(ui.kills == 0 and not ui.confirmation.visible, "initial count and feedback clear")
	player.health.max_hp = 225
	player.health.reset()
	ui.refresh_health()
	expect(ui.health_bar.max_value == 225 and ui.health_bar.value == 225 and ui.health_text.text == "HEALTH  225.0 / 225.0", "actual nondefault max HP")
	player.apply_damage(65)
	ui.refresh_health()
	expect(ui.health_bar.value == 160 and ui.health_text.text == "HEALTH  160.0 / 225.0", "actual damage updates health")
	player.health.reset()
	await get_tree().process_frame
	await get_tree().process_frame
	expect(ui.health_bar.value == 225, "silent Health.reset refreshes")
	scene._toggle_player_ui()
	expect(not ui.visible and scene.get_node("HUD/Crosshair").visible, "F1 hides health/count but preserves crosshair")
	scene._toggle_teammate_ui()
	expect(not ui.visible, "F2 does not restore player UI")
	scene._toggle_teammate_ui()
	scene._toggle_player_ui()
	expect(ui.visible, "F1 restores health/count")
	await arrive(scene)
	var victim: ActorBase = scene.enemies.crashies
	weapon._apply_hit_damage(victim, victim.global_position + Vector3.UP * 1.2, player)
	expect(ui.kills == 0, "nonlethal hit gives no kill")
	weapon._apply_hit_damage(victim, victim.global_position + Vector3.UP * 1.9, player)
	expect(ui.kills == 1 and ui.confirmation.visible, "player lethal hit produces count and pulse")
	await get_tree().physics_frame
	await get_tree().physics_frame
	expect(not victim.visible and victim.collision_layer == 0, "dead enemy disappearance preserved")
	weapon._apply_hit_damage(victim, victim.global_position + Vector3.UP * 1.9, player)
	scene._on_rifle_kill(victim, player, scene._round_serial)
	expect(ui.kills == 1, "dead actor damage and duplicate death count once")
	var other: ActorBase = scene.enemies.chronicle
	weapon._apply_hit_damage(other, other.global_position + Vector3.UP * 1.9, scene.teammate)
	expect(ui.kills == 1, "teammate kill excluded even on player weapon signal")
	scene.enemies.kaajak.apply_damage(1000)
	expect(ui.kills == 1, "unattributed death excluded")
	await capture("-kill")
	var old_serial: int = scene._round_serial
	await restart(scene)
	expect(ui.kills == 0 and not ui.confirmation.visible and not scene._victory_screen.visible, "restart clears count, animation and result")
	expect(ui.health_bar.value == scene._scenario.player_hp, "restart restores configured player health")
	await arrive(scene)
	victim = scene.enemies.crashies
	victim.apply_damage(1000)
	scene._on_utility_kill(victim, "ally", scene._round_serial)
	expect(ui.kills == 0, "teammate utility attribution excluded")
	scene._on_rifle_kill(victim, player, old_serial)
	expect(ui.kills == 0, "previous-round callback rejected for current victim")
	# Exercise the actual physics raycast and signal wiring, without spread.
	victim = scene.enemies.chronicle
	victim.global_position = player.global_position + Vector3(0, 0, -3)
	victim.set_physics_process(false)
	victim.health.hp = 1
	weapon.spread_base = 0
	weapon.spread_firing = 0
	weapon._cooldown = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	weapon.fire(victim.global_position + Vector3(0, 1.2, 1), Vector3.FORWARD, false, player)
	expect(ui.kills == 1, "physical hitscan kill reaches real scene UI")
	# Exercise molly overlap damage and owner propagation through utility system.
	victim = scene.enemies.kaajak
	victim.global_position = player.global_position + Vector3(0, 0, -6)
	victim.set_physics_process(false)
	victim.health.hp = 1
	var molly: Molly = scene.utility.throw_molly(victim.global_position, Vector3.ZERO, "player")
	molly.freeze = true
	while not molly.is_active:
		await get_tree().physics_frame
	for _i in range(40):
		await get_tree().physics_frame
	expect(not victim.is_alive and ui.kills == 2, "player molly lethal tick attributed once")
	await get_tree().create_timer(1.1).timeout
	expect(not ui.confirmation.visible, "kill effect expires")
	scene.enemies.boaster.apply_damage(1000)
	await get_tree().physics_frame
	await get_tree().physics_frame
	scene._update_round_label()
	expect(scene._round_state == "enemies_eliminated" and ui.result_title.text == "VICTORY" and scene._victory_screen.visible, "elimination victory preserved")
	await restart(scene)
	player.apply_damage(1000)
	ui.refresh_health()
	scene._update_round_label()
	expect(ui.health_bar.value == 0 and scene._round_state == "active" and not scene._victory_screen.visible, "player death at zero HP allows living ally to continue")
	scene.teammate.apply_damage(1000)
	scene._update_round_label()
	expect(scene._round_state == "player_down" and ui.result_title.text == "DEFEAT" and ui.result_reason.text == "Player and teammate eliminated", "team elimination defeat reason")
	expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "defeat releases mouse")
	await capture("-defeat")
	await restart(scene)
	weapon._apply_hit_damage(scene.teammate, scene.teammate.global_position + Vector3.UP * 1.9, player)
	expect(ui.kills == 0, "player friendly-fire death excluded from enemy kills")
	scene._update_round_label()
	expect(scene._round_state == "active" and not scene._victory_screen.visible, "ally death with living player continues")
	player.apply_damage(1000)
	scene._update_round_label()
	expect(ui.result_title.text == "DEFEAT" and scene._victory_screen.visible, "reverse death order also defeats")
	await restart(scene)
	scene._spike.defuse_step(scene._spike.global_position, 10.0)
	scene._update_round_label()
	expect(scene._round_state == "defused" and ui.result_title.text == "DEFEAT" and ui.result_reason.text == "Spike defused", "actual spike defuse defeat")
	scene._toggle_player_ui()
	expect(scene._victory_screen.visible, "F1 cannot hide terminal result")
	scene._toggle_player_ui()
	await restart(scene)
	scene._spike._physics_process(100)
	scene._update_round_label()
	expect(scene._round_state == "detonated" and ui.result_title.text == "VICTORY" and ui.result_reason.text == "Spike detonated", "actual detonation win")
	await capture("-victory")
	await restart(scene)
	await get_tree().create_timer(1.1).timeout
	expect(not scene._victory_screen.visible and not ui.confirmation.visible and ui.kills == 0, "restart leaves no stale result or pending effect")
	if not failed:
		print("PERSON2_COMBAT_UI_PASS checks=", checks)
	get_tree().quit(1 if failed else 0)
