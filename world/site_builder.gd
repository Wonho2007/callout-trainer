extends "res://world/sandbox_builder.gd"
# Reuse Person 3's source map; adapt scenario heights/Pit volume and add one
# platform access ramp. Plant in Pit, human in Heaven, no guessed enemy starts.
func _load_map(path: String) -> Dictionary:
	var map: Dictionary = super._load_map(path)
	if map.is_empty():
		return map
	var coverage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/site_coverage.json"))
	map.id = coverage.map_id
	map["region_precedence"] = "list_order"
	# The source Pit footprint is unchanged; its volume must include the new
	# -3m floor so occupants still receive the correct regional callout.
	for region in map.regions:
		if region.id == "b_pit":
			region.center[1] = 0.5
			region.size[1] = 8.0
	map.spawns = [{"id": "spawn_player", "role": "player", "position": coverage.player_spawn.position, "facing_deg": coverage.player_spawn.facing_deg}]
	map.spike = {"position": coverage.motion_markers.b_pit.position, "planted": true, "site_region": "b_pit"}
	return map

func _build_floor(map: Dictionary, parent: Node3D) -> void:
	super._build_floor(map, parent)
	# Scenario-only access to the new 2m Upper/Heaven platform. The source
	# authoring map remains unchanged. Surface ends meet ground and platform.
	_build_solid_box({"id": "scenario_upper_access", "position": [10.0, 0.863, -3.811],
		"size": [1.8, 0.3, 4.924], "rotation_deg": [23.962, 0, 0]}, parent, Color(0.5, 0.53, 0.58))

func _bake_navigation(nav_region: NavigationRegion3D) -> void:
	# CSG pit collision is generated at the end of the frame. Bake actual
	# collision after that synchronization, including the recessed floor.
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_region.navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	await super._bake_navigation(nav_region)
