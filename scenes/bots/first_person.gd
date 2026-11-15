extends "res://scenes/main.gd"
# Owned integration scene derived from Person 1's main, without editing it.
const BotScene = preload("res://scenes/bots/bot.tscn")
const Runtime = preload("res://bots/teammate_runtime.gd")
const RegionBelief = preload("res://belief/region_belief.gd")
const SceneSensor = preload("res://perception/scene_sensor.gd")
var teammate: ActorBase
var runtime: Node
var _bot_status: Label
var _round_serial: int = 0
var _comm_status: String = "Voice service not connected. Safe fallback active."
var _restart_pending: bool = false
var _scenario: Dictionary = {}
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
	print("PERSON2_FIRST_PERSON_READY map=", builder.map_path, " voice_backend=not_connected")

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
		{"enemy": _target}, _scenario.perception, int(_scenario.perception_seed), _round_serial, _player))
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
	_restart_pending = false

func _smoke_silence_player_input() -> void:
	# The smoke fixture drives shared player movement explicitly. No microphone
	# or user gameplay input is simulated in the normal scene.
	_player.set_physics_process(false)
