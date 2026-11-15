extends "res://scenes/main.gd"
# Owned integration scene derived from Person 1's main, without editing it.
const BotScene = preload("res://scenes/bots/bot.tscn")
const Runtime = preload("res://bots/teammate_runtime.gd")
const RegionBelief = preload("res://belief/region_belief.gd")
const SceneSensor = preload("res://perception/scene_sensor.gd")
const InfoPanel = preload("res://scenes/bots/teammate_info_panel.gd")
var teammate: ActorBase
var runtime: Node
var _bot_status: Label
var _round_serial: int = 0
var _comm_status: String = "Voice service not connected. Safe fallback active."
var _restart_pending: bool = false
var _scenario: Dictionary = {}
var _info_panel: PanelContainer
var _enemy_driving: bool = false
signal teammate_ready(bot_runtime: Node)

func _enter_tree() -> void:
	# Local integration accommodation for the documented Person 1 nav mismatch.
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.2)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)

func _ready() -> void:
	await super._ready()
	await get_tree().physics_frame
	await get_tree().process_frame
	_scenario = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/b_site_coverage.json"))
	var actual_regions: Array = []
	for region in builder.map_data.regions:
		actual_regions.append(region.id)
	actual_regions.sort()
	var configured_regions: Array = _scenario.planner.regions.duplicate()
	configured_regions.sort()
	if builder.map_data.id != _scenario.map_id or actual_regions != configured_regions:
		push_error("Person 2 coverage scenario does not match the loaded map/regions")
		get_tree().quit(1)
		return
	_bot_status = Label.new()
	_bot_status.position = Vector2(12, 160)
	_bot_status.add_theme_font_size_override("font_size", 17)
	$HUD.add_child(_bot_status)
	_info_panel = InfoPanel.new()
	_info_panel.name = "TeammateInformation"
	$HUD.add_child(_info_panel)
	_info_panel.enemy_preset_requested.connect(_test_enemy_preset)
	_info_panel.enemy_placement_requested.connect(_test_enemy_at_crosshair)
	_info_panel.flash_test_requested.connect(_test_flash_teammate)
	_mark_test_enemy()
	_spawn_teammate()
	if OS.get_cmdline_user_args().has("--first-person-smoke"):
		var smoke = load("res://tests/person2/first_person_smoke.gd").new()
		add_child(smoke)
		_smoke_silence_player_input()
		smoke.run(self)
	if OS.get_cmdline_user_args().has("--perception-smoke"):
		var smoke = load("res://tests/person2/scene_perception_smoke.gd").new()
		add_child(smoke)
		_smoke_silence_player_input()
		smoke.run(self)
	if OS.get_cmdline_user_args().has("--hud-smoke"):
		var smoke = load("res://tests/person2/teammate_hud_smoke.gd").new()
		add_child(smoke)
		_smoke_silence_player_input()
		smoke.run(self)
	print("PERSON2_FIRST_PERSON_READY map=", builder.map_path, " voice_backend=not_connected")

func _mark_test_enemy() -> void:
	# Owned test presentation on the inherited actor instance. Normal depth
	# testing keeps this label from revealing a target through walls.
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.24, 0.18)
	_target.get_node("MeshInstance3D").material_override = material
	var label := Label3D.new()
	label.name = "TestEnemyLabel"
	label.text = "TEST ENEMY"
	label.modulate = Color(1, 0.35, 0.25)
	label.position.y = 2.1
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	_target.add_child(label)

func _spawn_teammate() -> void:
	_round_serial += 1
	teammate = BotScene.instantiate()
	add_child(teammate)
	teammate.died.connect(_on_teammate_died)
	# Person 1's new room has player/enemy markers only. Teammate placement is
	# authored in this lane's scenario, rather than editing shared map data.
	var spawn := Marker3D.new()
	add_child(spawn)
	var point: Array = _scenario.teammate_spawn.position
	spawn.position = Vector3(point[0], point[1], point[2])
	spawn.rotation_degrees.y = _scenario.teammate_spawn.facing_deg
	teammate.teleport_to(spawn)
	spawn.free()
	var belief = RegionBelief.new("ally", _scenario.planner.regions, ["enemy"])
	runtime = Runtime.new()
	runtime.name = "TeammateRuntime"
	add_child(runtime)
	runtime.configure("ally", teammate, builder, belief, _scenario.planner,
		_scenario.motion_markers, _scenario.entries, _round_serial, utility, _scenario.flash_targets, int(_scenario.flash_charges))
	runtime.attach_perception(SceneSensor.new("ally", teammate, builder, utility,
		{"enemy": _target}, _scenario.perception, int(_scenario.perception_seed), _round_serial, _player, _scenario.player_entry_sensing))
	runtime.comm_result.connect(_comm_result)
	teammate_ready.emit(runtime)

func _verify_navigation() -> void:
	# Person 1 calls this from the ready signal's physics continuation. Let
	# server synchronization finish before exercising its actual path check.
	await get_tree().physics_frame
	await get_tree().process_frame
	# Check actual current-map anchors, replacing the inherited scaffold check
	# which still looks for region_a/region_b from the old test room.
	var spawn: Marker3D = builder.get_spawn("player")
	var point: Variant = builder.get_region_center("entry")
	if spawn == null or point == null or builder.query_path(spawn.global_position, point).is_empty():
		push_error("Person 2: current-map player-to-entry navigation check failed")

func _comm_result(result: Dictionary) -> void:
	_comm_status = "Comm: " + result.status + " / " + result.reason_code

func _process(delta: float) -> void:
	super._process(delta)
	if is_instance_valid(_bot_status) and is_instance_valid(runtime):
		var state: Dictionary = runtime.snapshot()
		var decision: Dictionary = state.plan.get("decision", {})
		_bot_status.text = "TEAMMATE: %s -> %s\n%s\nMap: %s (synthetic)" % [
			decision.get("goal", "waiting"), decision.get("target_id", ""), _comm_status, builder.map_data.id]
		_info_panel.update_information(state)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_F6:
				_test_enemy_preset("entry")
				get_viewport().set_input_as_handled()
				return
			KEY_F7:
				_test_enemy_preset("room")
				get_viewport().set_input_as_handled()
				return
			KEY_P:
				_test_enemy_at_crosshair()
				get_viewport().set_input_as_handled()
				return
			KEY_F8:
				_test_flash_teammate()
				get_viewport().set_input_as_handled()
				return
	super._unhandled_input(event)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _restart_pending or not is_instance_valid(_target) or not _target.is_alive or not is_instance_valid(_player):
		return
	var horizontal: float = float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
	var depth: float = float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
	var direction: Vector3 = _player.global_basis * Vector3(horizontal, 0, depth)
	direction.y = 0
	if not direction.is_zero_approx() or _enemy_driving:
		# Shared ActorBase resolves normal speed/gravity/collision and real run
		# audio. Leave unrelated fixture/AI intent alone when tools are idle.
		_target.set_move_dir(direction.normalized())
		_enemy_driving = not direction.is_zero_approx()

func _test_enemy_preset(preset: String) -> void:
	if not _scenario.get("test_enemy_positions", {}).has(preset):
		return
	var p: Array = _scenario.test_enemy_positions[preset]
	_place_test_enemy(Vector3(p[0], p[1], p[2]))

func _test_enemy_at_crosshair() -> void:
	if _restart_pending or not is_instance_valid(_player) or not is_instance_valid(_info_panel):
		return
	var camera: Camera3D = _player.camera
	var origin: Vector3 = camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin - camera.global_basis.z * 40, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.65:
		_info_panel.set_tool_feedback("Aim at an open floor, then press P.")
		return
	_place_test_enemy(hit.position)

func _place_test_enemy(point: Vector3) -> bool:
	# PRIVILEGED test control. Placement never creates an observation/report.
	if _restart_pending or not is_instance_valid(_target) or not is_instance_valid(teammate) or not builder.navigation_is_ready or not point.is_finite():
		return false
	var anchor: Vector3 = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, point)
	if anchor.distance_to(point) > 0.75 or point.distance_to(teammate.global_position) < 0.8 or point.distance_to(_player.global_position) < 0.8:
		_info_panel.set_tool_feedback("Choose open, walkable floor away from the actors.")
		return false
	var collision: CollisionShape3D = _target.get_node("CollisionShape3D")
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = collision.shape
	shape_query.collision_mask = 1
	shape_query.transform = Transform3D(Basis.IDENTITY, point + collision.position + Vector3.UP * 0.05)
	if not get_world_3d().direct_space_state.intersect_shape(shape_query, 1).is_empty():
		_info_panel.set_tool_feedback("Enemy needs clear standing room here.")
		return false
	var marker := Marker3D.new()
	add_child(marker)
	marker.global_position = point + Vector3.UP * 0.03
	_target.teleport_to(marker)
	_target.set_move_dir(Vector3.ZERO)
	marker.free()
	_enemy_driving = false
	_info_panel.set_tool_feedback("Enemy moved. Teammate must see or hear it normally.")
	return true

func _test_flash_teammate() -> void:
	if _restart_pending or not is_instance_valid(teammate) or not teammate.is_alive:
		return
	# Actual shared fuse/LOS/duration, placed ahead for a repeatable manual test.
	# Never writes a sensor blind flag or consumes a teammate command charge.
	var forward: Vector3 = -teammate.global_basis.z
	var flash: Node3D = utility.throw_flash(teammate.global_position + Vector3.UP * 1.6 + forward * 2, Vector3.ZERO)
	if flash != null:
		flash.freeze = true
		_info_panel.set_tool_feedback("Test flash spawned ahead of teammate; waiting for fuse.")
		flash.detonated.connect(func(_position: Vector3): _info_panel.set_tool_feedback("Flash detonated. Check teammate Vision above."))

func _on_player_died() -> void:
	# A surviving teammate continues; player voice input may remain connected.
	if is_instance_valid(teammate) and teammate.is_alive:
		return
	super._on_player_died()
	if is_instance_valid(runtime):
		runtime.finish_round("team_eliminated")

func _on_teammate_died() -> void:
	if is_instance_valid(_player) and not _player.is_alive and _round_state == "active":
		_round_state = "player_down"
		if is_instance_valid(runtime):
			runtime.finish_round("team_eliminated")

func _on_spike_defused() -> void:
	super._on_spike_defused()
	if is_instance_valid(runtime):
		runtime.finish_round("defused")

func _on_spike_detonated() -> void:
	super._on_spike_detonated()
	if is_instance_valid(runtime):
		runtime.finish_round("detonated")

func _restart() -> void:
	if _restart_pending:
		return
	_restart_pending = true
	_enemy_driving = false
	if is_instance_valid(_target):
		_target.set_move_dir(Vector3.ZERO)
	if is_instance_valid(runtime):
		runtime.free()
	if is_instance_valid(teammate):
		teammate.free()
	super._restart()
	await builder.navigation_ready
	await get_tree().physics_frame
	await get_tree().process_frame
	_spawn_teammate()
	_comm_status = "Voice service not connected. Safe fallback active."
	_enemy_driving = false
	_info_panel.set_tool_feedback("Round reset. F6 brings enemy into initial teammate view.")
	_restart_pending = false

func _smoke_silence_player_input() -> void:
	# The smoke fixture drives shared player movement explicitly. No microphone
	# or user gameplay input is simulated in the normal scene.
	_player.set_physics_process(false)
