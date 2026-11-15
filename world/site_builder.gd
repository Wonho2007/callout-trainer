extends "res://world/sandbox_builder.gd"
# Person 3's map geometry/zones are used verbatim. Only scenario metadata changes:
# plant in Pit, human starts Heaven, no guessed enemy spawn markers.
func _load_map(path: String) -> Dictionary:
	var map: Dictionary = super._load_map(path)
	if map.is_empty():
		return map
	var coverage: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/site_coverage.json"))
	map.id = coverage.map_id
	map["region_precedence"] = "list_order"
	map.spawns = [{"id": "spawn_player", "role": "player", "position": coverage.player_spawn.position, "facing_deg": coverage.player_spawn.facing_deg}]
	map.spike = {"position": coverage.motion_markers.b_pit.position, "planted": true, "site_region": "b_pit"}
	return map
