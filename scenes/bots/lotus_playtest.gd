extends "res://scenes/bots/voice_playtest.gd"
const SpawnSchedule = preload("res://scenarios/first_known_spawns.gd")
const RetakePolicy = preload("res://bots/retake_policy.gd")
const AnnotationPolicy = preload("res://bots/annotation_policy.gd")
const AnnotationExecutor = preload("res://bots/annotation_executor.gd")
var enemies: Dictionary = {}
var enemy_runtimes: Dictionary = {}
var _annotation: Dictionary = {}
var _utility_executors: Dictionary = {}
var _remote_smoke_done: bool = false
var _flash_indicators: Dictionary = {}
var schedule: RefCounted
var scenario_tick: int = -1
var _plant_active: bool = false
var _scenario_status: Label
var _victory_screen: ColorRect

func _ready() -> void:
	await super._ready()
	_scenario_status = Label.new()
	_scenario_status.position = Vector2(12, 262)
	_scenario_status.text = "Seven-region authored approximation\nPlayer: Something / Yoru (PRX). Enemies arrive at first known positions."
	_scenario_status.add_theme_font_size_override("font_size", 14)
	$HUD.add_child(_scenario_status)
	_add_region_labels()
	_build_victory_screen()
	_info_panel.set_test_tools_enabled(false)
	_info_panel.position.y = 315
	$HUD/Hints.text = "WASD | LMB fire | R reload | B dash | V talk | F restart | Esc mouse | F1 player UI | F2 teammate UI"
	_begin_plant()
	if OS.get_cmdline_user_args().has("--lotus-smoke"):
		var smoke = load("res://tests/person2/lotus_smoke.gd").new()
		add_child(smoke)
		_smoke_silence_player_input()
		smoke.run(self)

func _spawn_target() -> void:
	# At plant all four FNC positions are unknown: no actors or colliders exist.
	_target = null

func _spawn_spike() -> void:
	super._spawn_spike()
	_spike.set_physics_process(false)

func _mark_test_enemy() -> void:
	pass

func _test_enemy_preset(_region: String) -> void:
	pass

func _test_enemy_at_crosshair() -> void:
	pass

func _test_flash_teammate() -> void:
	pass


func _opponent_registry() -> Dictionary:
	return enemies.duplicate()

func _belief_enemy_ids() -> Array:
	return _scenario.enemy_ids.duplicate()

func _spawn_teammate() -> void:
	super._spawn_teammate()
	_annotation = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/fnc_prx_lotus_toronto2024_gf.json"))
	runtime.attach_scenario_policy(AnnotationPolicy.new("ally", _annotation.timeline, 0, int(_scenario.get("utility_grace_ticks", 120))))
	_utility_executors["ally"] = AnnotationExecutor.new("ally", teammate, runtime, utility, _scenario.motion_markers)
	teammate.health.max_hp = float(_scenario.ally_hp)
	teammate.health.reset()
	if not OS.get_cmdline_user_args().has("--lotus-smoke") and not OS.get_cmdline_user_args().has("--site-smoke"):
		runtime.enable_combat(utility)

func _begin_plant() -> void:
	schedule = SpawnSchedule.new(_scenario.spawn_schedule)
	scenario_tick = -1
	_plant_active = true
	_remote_smoke_done = false
	_spike.reset()
	_player.health.max_hp = float(_scenario.player_hp)
	_player.health.reset()
	_wire_all_minimap()

func _physics_process(delta: float) -> void:
	# PRX is defending its own plant: player cannot defuse the planted spike.
	if not _plant_active or _restart_pending or _round_state != "active":
		return
	scenario_tick += 1
	for spec in schedule.due(scenario_tick):
		_materialize(spec)
	# This remote smoke is an observed effect with unknown caster position.
	# It never creates a Boaster actor or injects location evidence.
	if scenario_tick >= 960 and not _remote_smoke_done:
		_remote_smoke_done = true
		var main: Array = _scenario.motion_markers.b_main.position
		utility.throw_smoke(Vector3(main[0] + 1.0, main[1], main[2]), "boaster")
	runtime.set_scenario_tick(scenario_tick)
	_execute_annotation_utility("ally", runtime)
	for id in enemy_runtimes:
		enemy_runtimes[id].set_scenario_tick(scenario_tick)
		_execute_annotation_utility(id, enemy_runtimes[id])
		var indicator: Label3D = _flash_indicators[id]
		indicator.visible = enemies[id].is_alive and enemies[id].get_meta("bot_blinded", false)
	var defusing: bool = false
	for id in enemy_runtimes:
		var actor: ActorBase = enemies[id]
		var status: Dictionary = enemy_runtimes[id].snapshot()
		var decision: Dictionary = status.plan.get("decision", {})
		if actor.is_alive and decision.get("target_id") == "b_pit" and status.combat.decision.get("action") != "engage" and _spike.in_range(actor.global_position):
			_spike.defuse_step(actor.global_position, delta)
			defusing = true
			break
	if not defusing:
		_spike.stop_defuse()
	if enemies.size() == _scenario.enemy_ids.size() and enemies.values().all(func(actor: ActorBase): return not actor.is_alive):
		_round_state = "enemies_eliminated"
		runtime.finish_round("enemies_eliminated")
		for enemy_runtime in enemy_runtimes.values():
			enemy_runtime.finish_round("enemies_eliminated")

func _materialize(spec: Dictionary) -> void:
	var actor: ActorBase = ActorScene.instantiate()
	actor.name = spec.actor_id
	add_child(actor)
	actor.health.max_hp = float(spec.hp)
	actor.health.reset()
	actor.global_position = Vector3(spec.position[0], spec.position[1], spec.position[2])
	actor.rotation_degrees.y = float(spec.facing_deg)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.22, 0.18)
	actor.get_node("MeshInstance3D").material_override = material
	enemies[spec.actor_id] = actor
	if _target == null:
		_target = actor
	var label := Label3D.new()
	label.text = spec.actor_id + " / " + spec.agent
	label.position.y = 2.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	actor.add_child(label)
	# No spawn testimony is injected. Ordinary exposure/LOS/delay discovers it.
	var configuration: Dictionary = _scenario.planner.duplicate(true)
	configuration.baseline_marker_id = spec.region_id
	configuration.baseline_watch_region = "b_pit"
	for marker in configuration.markers:
		if "b_pit" not in marker.watch_regions:
			marker.watch_regions.append("b_pit")
	var belief = RegionBelief.new(spec.actor_id, configuration.regions, ["player", "ally"])
	var enemy_runtime = Runtime.new()
	add_child(enemy_runtime)
	enemy_runtime.configure(spec.actor_id, actor, builder, belief, configuration, _scenario.motion_markers, {}, _round_serial, utility)
	enemy_runtime.attach_perception(SceneSensor.new(spec.actor_id, actor, builder, utility,
		{"player": _player, "ally": teammate}, _scenario.perception, int(_scenario.perception_seed) + enemies.size(), _round_serial))
	enemy_runtime.attach_scenario_policy(AnnotationPolicy.new(spec.actor_id, _annotation.timeline, int(spec.first_known_tick), int(_scenario.get("utility_grace_ticks", 120))))
	if not OS.get_cmdline_user_args().has("--lotus-smoke") and not OS.get_cmdline_user_args().has("--site-smoke"):
		enemy_runtime.enable_combat(utility)
	runtime.register_opponent(spec.actor_id, actor)
	enemy_runtimes[spec.actor_id] = enemy_runtime
	actor.died.connect(_wire_all_minimap)
	_utility_executors[spec.actor_id] = AnnotationExecutor.new(spec.actor_id, actor, enemy_runtime, utility, _scenario.motion_markers)
	var indicator := Label3D.new()
	indicator.name = "FlashIndicator"
	indicator.text = "●"
	indicator.font_size = 64
	indicator.pixel_size = 0.006
	indicator.position.y = 1.95
	indicator.modulate = Color.WHITE
	indicator.outline_size = 0
	indicator.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	indicator.no_depth_test = false
	indicator.visible = false
	actor.add_child(indicator)
	_flash_indicators[spec.actor_id] = indicator
	_wire_all_minimap()
	print("PERSON2_ANNOTATED_ARRIVAL actor=", spec.actor_id, " tick=", scenario_tick, " region=", spec.region_id)

func _execute_annotation_utility(id: String, bot_runtime: Node) -> void:
	for beat in bot_runtime.take_scenario_utility():
		var released: bool = _utility_executors[id].execute(beat)
		print("PERSON2_ANNOTATED_UTILITY actor=", id, " action=", beat.action, " region=", beat.region, " tick=", scenario_tick, " released=", released)

func _wire_all_minimap() -> void:
	var living: Array = enemies.values().filter(func(actor: ActorBase): return actor.is_alive)
	_player.scan_targets = living
	var minimap: Node = get_node_or_null("HUD/Minimap")
	if minimap != null:
		minimap.builder = builder
		minimap.player = _player
		minimap.enemies = living
		minimap.utility = utility
		minimap.refresh()

func _verify_navigation() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	if builder.query_path(Vector3(0, 0, 9), Vector3(7.5, 1.6, -8)).is_empty():
		push_error("Seven-region floor-to-Heaven navigation missing")

func _build_victory_screen() -> void:
	# Full-screen overlay shown when all opponents are eliminated. It sits above
	# the gameplay HUD and is ignored by mouse input so it never blocks clicks.
	_victory_screen = ColorRect.new()
	_victory_screen.name = "VictoryScreen"
	_victory_screen.color = Color(0.03, 0.06, 0.04, 0.82)
	_victory_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_screen.visible = false
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_screen.add_child(center)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	var title := Label.new()
	title.name = "Title"
	title.text = "VICTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.6, 0.95, 0.65))
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "All opponents eliminated"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 28)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.95, 0.88))
	column.add_child(subtitle)
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = "Press F to play again"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.7, 0.8, 0.75))
	column.add_child(prompt)
	$HUD.add_child(_victory_screen)

func _show_victory(shown: bool) -> void:
	if is_instance_valid(_victory_screen):
		_victory_screen.visible = shown
	if shown and is_instance_valid(_player):
		# Release the mouse so the player can read the screen and click away.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _update_round_label() -> void:
	_show_victory(_round_state == "enemies_eliminated")
	var label: Label = get_node_or_null("HUD/Round")
	if label == null or _spike == null:
		return
	if _round_state == "active":
		label.text = "PRX plant hold | Spike %.1fs | FNC defuse %.0f%% | F restart" % [_spike.time_left, _spike.defuse_progress * 100]
	else:
		var won: bool = _round_state in ["detonated", "enemies_eliminated"]
		label.text = ("PRX hold succeeds" if won else "FNC retake succeeds") + " — " + _round_state + " | F restart"

func _update_status() -> void:
	_update_round_label()
	if not is_instance_valid(_player):
		return
	var weapon: Node = _player.get_node("Camera3D/Weapon")
	$HUD/Status.text = "HP: %d | Ammo: %d/%d | %s" % [_player.health.hp, weapon.in_mag, weapon.reserve, "ALIVE" if _player.is_alive else "DOWN — voice still available"]

func _stop_enemies(reason: String) -> void:
	for enemy_runtime in enemy_runtimes.values():
		enemy_runtime.finish_round(reason)

func _on_spike_defused() -> void:
	super._on_spike_defused()
	_stop_enemies("defused")

func _on_spike_detonated() -> void:
	super._on_spike_detonated()
	_stop_enemies("detonated")

func _on_player_died() -> void:
	super._on_player_died()
	if _round_state != "active":
		_stop_enemies("team_eliminated")

func _on_teammate_died() -> void:
	super._on_teammate_died()
	if _round_state != "active":
		_stop_enemies("team_eliminated")

func _restart() -> void:
	if _restart_pending:
		return
	_plant_active = false
	utility.clear_effects()
	_utility_executors.clear()
	_flash_indicators.clear()
	for enemy_runtime in enemy_runtimes.values():
		enemy_runtime.free()
	enemy_runtimes.clear()
	for actor in enemies.values():
		actor.free()
	enemies.clear()
	_target = null
	await super._restart()
	_begin_plant()

func _add_region_labels() -> void:
	for region in builder.map_data.regions:
		var label := Label3D.new()
		label.text = region.name
		label.position = Vector3(region.center[0], 3.8 if region.id != "b_heaven" else 5.4, region.center[2])
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = false
		add_child(label)
