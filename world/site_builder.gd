extends "res://world/sandbox_builder.gd"
# Reuse source geometry, with authored jump links over existing box_3.
const JUMP_LEGS = [[Vector3(11.0, 0.1, -3.4), Vector3(12.405, 1.1, -3.4)],
	[Vector3(12.405, 1.1, -4.9), Vector3(11.6, 2.1, -6.5)]]
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

func _bake_navigation(nav_region: NavigationRegion3D) -> void:
	# CSG pit collision is generated at the end of the frame. Bake actual
	# collision after that synchronization, including the recessed floor.
	await get_tree().physics_frame
	await get_tree().physics_frame
	nav_region.navigation_mesh.cell_size = 0.1
	nav_region.navigation_mesh.agent_radius = 0.3
	nav_region.navigation_mesh.region_min_size = 0.0
	nav_region.navigation_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	for index in range(JUMP_LEGS.size()):
		var link := NavigationLink3D.new()
		link.name = "BoxJump" + str(index)
		link.start_position = JUMP_LEGS[index][0]
		link.end_position = JUMP_LEGS[index][1]
		link.bidirectional = true
		nav_region.add_child(link)
	await super._bake_navigation(nav_region)

func is_jump_landing(point: Vector3) -> bool:
	for leg in JUMP_LEGS:
		if point.distance_to(leg[0]) < 0.25 or point.distance_to(leg[1]) < 0.25:
			return true
	return false

func jump_surface(point: Vector3) -> Vector3:
	# Recast path points sit above the collision surface. Land on the actual
	# authored box/platform height, not on the navigation voxel offset.
	for leg in JUMP_LEGS:
		for endpoint in leg:
			if point.distance_to(endpoint) < 0.25:
				return endpoint - Vector3.UP * 0.1
	return point

func jump_leg(from: Vector3, to: Vector3) -> bool:
	for leg in JUMP_LEGS:
		if (to.distance_to(leg[1]) < 0.25 and from.distance_to(leg[0]) < 0.75) or (to.distance_to(leg[0]) < 0.25 and from.distance_to(leg[1]) < 0.75):
			return true
	return false
