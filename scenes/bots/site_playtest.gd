extends "res://scenes/bots/lotus_playtest.gd"
# Reuse plant/baseline/voice mechanics on Person 3's measured-zone greybox.
func _enter_tree() -> void:
	super._enter_tree()
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.1)

func _ready() -> void:
	await super._ready()
	_scenario_status.text = "Seven-zone B site map (Person 3)\nPlant hold: player starts Heaven; enemies arrive at first known positions."
	if OS.get_cmdline_user_args().has("--site-smoke"):
		var smoke = load("res://tests/person2/site_smoke.gd").new()
		add_child(smoke)
		_smoke_silence_player_input()
		smoke.run(self)

func _verify_navigation() -> void:
	await get_tree().physics_frame
	await get_tree().process_frame
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/site_coverage.json"))
	var start: Array = data.motion_markers.b_pit.position
	var origin := Vector3(start[0], start[1], start[2])
	for marker in data.motion_markers.values():
		var p: Array = marker.position
		var destination := Vector3(p[0], p[1], p[2])
		var path: PackedVector3Array = builder.query_path(origin, destination)
		if path.is_empty() or path[0].distance_to(origin) > 0.75 or path[-1].distance_to(destination) > 0.75:
			push_error("B-site scenario marker is not connected to Pit: " + str(destination))

func _add_region_labels() -> void:
	for region in builder.map_data.regions:
		var label := Label3D.new()
		label.text = region.name
		label.position = Vector3(region.center[0], 3.8, region.center[2])
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)

func _update_status() -> void:
	super._update_status()
	_update_coords()
