extends Node3D
## Sandbox builder (Person 1).
##
## Reads a synthetic map JSON (world/maps/*.json) and generates the greybox
## world from data: floor, walls and cover (each with matching collision),
## named callout regions as Area3D trigger volumes, and spawn markers.
##
## Conventions (docs/CONTRACTS.md): meters, Y up, Vector3 serialized as
## [x, y, z]. A box's "position" is its center; "size" is full extents.
##
## This builder only creates static geometry/regions/spawns. It does NOT
## create actors, bots, navigation bake, or any gameplay. Navigation baking
## is a separate, later Person 1 step. Collision and navigation are distinct
## systems; generating collision does not make the room navigable.
##
## Rebuildable: build() clears previously generated children first, so calling
## it again (e.g. on restart) does not duplicate nodes.

## Collision layer bits, matching project.godot [layer_names].
const LAYER_WORLD: int = 1 << 0    # layer 1 "world"
const LAYER_REGIONS: int = 1 << 3  # layer 4 "regions"

@export_file("*.json") var map_path: String = "res://world/maps/test_room.json"
## Build automatically when the scene is ready. Turn off to build manually.
@export var build_on_ready: bool = true

## Parsed map data, kept for other systems (spawns, region lookup) to query.
var map_data: Dictionary = {}

## Emitted after the navigation mesh has finished baking and the nav map has
## synchronized, so consumers can safely query paths. Person 2 should await or
## connect to this before using NavigationServer3D path queries.
signal navigation_ready

## True once navigation_ready has fired for the current build.
var navigation_is_ready: bool = false

## Container names so a rebuild can find and clear what it made.
const GEOMETRY_ROOT := "NavRegion"  # NavigationRegion3D parenting the geometry
const REGIONS_ROOT := "Regions"
const SPAWNS_ROOT := "Spawns"


func _ready() -> void:
	if build_on_ready:
		var err := build_from_file(map_path)
		if err != OK:
			push_error("sandbox_builder: build failed for '%s' (error %d)" % [map_path, err])


## Load JSON from disk and build. Returns OK or an error code; never half-builds.
func build_from_file(path: String) -> int:
	var parsed := _load_map(path)
	if parsed.is_empty():
		return ERR_PARSE_ERROR
	var validation := validate_map(parsed)
	if not validation.is_empty():
		for msg in validation:
			push_error("sandbox_builder: invalid map '%s': %s" % [path, msg])
		return ERR_INVALID_DATA
	map_data = parsed
	_build(parsed)
	return OK


func _load_map(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("sandbox_builder: map file not found: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parse_err := json.parse(text)
	if parse_err != OK:
		push_error("sandbox_builder: JSON parse error in %s at line %d: %s"
			% [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("sandbox_builder: map root is not an object: %s" % path)
		return {}
	return json.data


## Validate the map data. Returns a list of human-readable problems;
## an empty list means the map is valid. Checks: required keys, unique IDs,
## positive sizes, boxes inside bounds, and spawn clearance from solids.
func validate_map(m: Dictionary) -> Array[String]:
	var problems: Array[String] = []

	for key in ["walls", "cover", "regions", "spawns"]:
		if not m.has(key) or typeof(m[key]) != TYPE_ARRAY:
			problems.append("missing or non-array key '%s'" % key)
	if not problems.is_empty():
		return problems

	var bounds_min := _to_vec3(m.get("bounds", {}).get("min", [-1e9, -1e9, -1e9]))
	var bounds_max := _to_vec3(m.get("bounds", {}).get("max", [1e9, 1e9, 1e9]))

	var seen_ids := {}
	var solids: Array = []
	solids.append_array(m["walls"])
	solids.append_array(m["cover"])

	# Walls form the perimeter: their thickness legitimately sits on or just
	# outside the play-area bounds, so only interior cover is bounds-checked.
	var cover_ids := {}
	for c in m["cover"]:
		cover_ids[String(c.get("id", ""))] = true

	for box in solids:
		var id := String(box.get("id", ""))
		if id.is_empty():
			problems.append("a wall/cover box has no id")
		elif seen_ids.has(id):
			problems.append("duplicate id '%s'" % id)
		else:
			seen_ids[id] = true
		var size := _to_vec3(box.get("size", [0, 0, 0]))
		if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
			problems.append("box '%s' has non-positive size %s" % [id, size])
		var pos := _to_vec3(box.get("position", [0, 0, 0]))
		if cover_ids.has(id) and not _box_within_bounds(pos, size, bounds_min, bounds_max):
			problems.append("cover '%s' extends outside map bounds" % id)

	for region in m["regions"]:
		var id := String(region.get("id", ""))
		if id.is_empty():
			problems.append("a region has no id")
		elif seen_ids.has(id):
			problems.append("duplicate id '%s'" % id)
		else:
			seen_ids[id] = true
		var size := _to_vec3(region.get("size", [0, 0, 0]))
		if size.x <= 0.0 or size.y <= 0.0 or size.z <= 0.0:
			problems.append("region '%s' has non-positive size %s" % [id, size])

	for spawn in m["spawns"]:
		var id := String(spawn.get("id", ""))
		if id.is_empty():
			problems.append("a spawn has no id")
		elif seen_ids.has(id):
			problems.append("duplicate id '%s'" % id)
		else:
			seen_ids[id] = true
		var pos := _to_vec3(spawn.get("position", [0, 0, 0]))
		for box in solids:
			var bpos := _to_vec3(box.get("position", [0, 0, 0]))
			var bsize := _to_vec3(box.get("size", [0, 0, 0]))
			if _point_in_box(pos, bpos, bsize):
				problems.append("spawn '%s' is inside solid '%s'"
					% [id, box.get("id", "?")])

	return problems


func _build(m: Dictionary) -> void:
	_clear_generated()
	navigation_is_ready = false

	# Geometry lives under a NavigationRegion3D so the navmesh bakes from the
	# same meshes that provide collision (collision and navigation are separate
	# systems; this keeps them generated from one source).
	var nav_region := NavigationRegion3D.new()
	nav_region.name = GEOMETRY_ROOT
	var nav_mesh := NavigationMesh.new()
	# Agent sizing: keep in sync with the player/bot capsule (radius ~0.3,
	# height ~1.8). Placeholders, tune in playtest.
	nav_mesh.agent_radius = 0.4
	nav_mesh.agent_height = 1.8
	nav_mesh.agent_max_climb = 0.4
	nav_mesh.cell_size = 0.2
	nav_mesh.cell_height = 0.1
	# Parse the generated visual box meshes as source geometry.
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_MESH_INSTANCES
	nav_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)

	_build_floor(m, nav_region)
	for wall in m["walls"]:
		_build_solid_box(wall, nav_region, Color(0.80, 0.82, 0.88))
	for box in m["cover"]:
		_build_solid_box(box, nav_region, Color(0.90, 0.45, 0.15))

	var regions := Node3D.new()
	regions.name = REGIONS_ROOT
	add_child(regions)
	for region in m["regions"]:
		_build_region(region, regions)

	var spawns := Node3D.new()
	spawns.name = SPAWNS_ROOT
	add_child(spawns)
	for spawn in m["spawns"]:
		_build_spawn(spawn, spawns)

	_build_lighting()
	_bake_navigation(nav_region)


## Bake the navmesh from the generated geometry, then wait for the nav map to
## synchronize before announcing readiness. Bots must not query paths earlier.
func _bake_navigation(nav_region: NavigationRegion3D) -> void:
	# bake_navigation_mesh() runs on a thread; it emits bake_finished when done.
	nav_region.bake_navigation_mesh()
	await nav_region.bake_finished
	# The baked mesh is applied, but the navigation server needs a physics frame
	# to synchronize the map before path queries return valid results.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var nm := nav_region.navigation_mesh
	var polys := nm.get_polygon_count() if nm else 0
	if polys == 0:
		push_warning("sandbox_builder: navmesh baked with 0 polygons — check geometry")
	navigation_is_ready = true
	navigation_ready.emit()


func _clear_generated() -> void:
	for container_name in [GEOMETRY_ROOT, REGIONS_ROOT, SPAWNS_ROOT, "Lighting"]:
		var existing := get_node_or_null(NodePath(container_name))
		if existing:
			existing.free()


func _build_floor(m: Dictionary, parent: Node3D) -> void:
	var floor_data: Dictionary = m.get("floor", {})
	var size2 = floor_data.get("size", [20, 20])
	var fx := float(size2[0])
	var fz := float(size2[1])
	var fy := float(floor_data.get("y", 0))
	# Represent the floor as a thin solid box so collision matches the mesh.
	var floor_box := {
		"id": "floor",
		"position": [0, fy - 0.05, 0],
		"size": [fx, 0.1, fz],
	}
	_build_solid_box(floor_box, parent, Color(0.30, 0.31, 0.34))


func _build_solid_box(box: Dictionary, parent: Node3D, color: Color = Color(0.6, 0.6, 0.62)) -> void:
	var id := String(box.get("id", "box"))
	var pos := _to_vec3(box.get("position", [0, 0, 0]))
	var size := _to_vec3(box.get("size", [1, 1, 1]))

	var body := StaticBody3D.new()
	body.name = id
	body.position = pos
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	parent.add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	# Shade faces by their normal so box edges read even with flat lighting.
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	# Matching collision generated from the same size (one record -> both).
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)


func _build_region(region: Dictionary, parent: Node3D) -> void:
	var id := String(region.get("id", "region"))
	var center := _to_vec3(region.get("center", [0, 0, 0]))
	var size := _to_vec3(region.get("size", [1, 1, 1]))

	var area := Area3D.new()
	area.name = id
	area.position = center
	area.collision_layer = LAYER_REGIONS
	area.collision_mask = 0
	area.monitoring = false  # a passive volume; detection is wired up later
	area.set_meta("region_id", id)
	area.set_meta("region_name", region.get("name", id))
	parent.add_child(area)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)


func _build_spawn(spawn: Dictionary, parent: Node3D) -> void:
	var id := String(spawn.get("id", "spawn"))
	var pos := _to_vec3(spawn.get("position", [0, 0, 0]))
	var facing := float(spawn.get("facing_deg", 0.0))

	var marker := Marker3D.new()
	marker.name = id
	marker.position = pos
	marker.rotation_degrees = Vector3(0, facing, 0)
	marker.set_meta("role", spawn.get("role", "unknown"))
	parent.add_child(marker)


func _build_lighting() -> void:
	var lighting := Node3D.new()
	lighting.name = "Lighting"
	add_child(lighting)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	lighting.add_child(sun)

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.20, 0.22, 0.26)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.48, 0.55)
	e.ambient_light_energy = 0.25
	env.environment = e
	lighting.add_child(env)


## Return the spawn marker for a role (e.g. "player"), or null if absent.
func get_spawn(role: String) -> Marker3D:
	var spawns := get_node_or_null(NodePath(SPAWNS_ROOT))
	if spawns == null:
		return null
	for child in spawns.get_children():
		if child is Marker3D and child.get_meta("role", "") == role:
			return child
	return null


## Planted spike world position from map data, or null if none defined.
func get_spike_position():
	if map_data.has("spike"):
		return _to_vec3(map_data["spike"].get("position", [0, 0, 0]))
	return null


## World-space center of a callout region by ID, or null if not found.
func get_region_center(region_id: String):
	var regions := get_node_or_null(NodePath(REGIONS_ROOT))
	if regions == null:
		return null
	for child in regions.get_children():
		if child.get_meta("region_id", "") == region_id:
			return child.global_position
	return null


## Query a navigation path between two world points on the baked navmesh.
## Returns an empty PackedVector3Array if navigation is not ready or no path
## exists. Person 2's actor controllers move bodies along the returned points;
## this builder does not move anything.
func query_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if not navigation_is_ready:
		push_warning("sandbox_builder: query_path called before navigation_ready")
		return PackedVector3Array()
	var map_rid := get_world_3d().navigation_map
	# Region centers sit above the floor; snap endpoints onto the navmesh so
	# the query starts and ends on walkable surface.
	var start := NavigationServer3D.map_get_closest_point(map_rid, from)
	var end := NavigationServer3D.map_get_closest_point(map_rid, to)
	return NavigationServer3D.map_get_path(map_rid, start, end, true)


# --- helpers ---

func _to_vec3(arr) -> Vector3:
	if typeof(arr) == TYPE_ARRAY and arr.size() >= 3:
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return Vector3.ZERO


func _box_within_bounds(center: Vector3, size: Vector3, bmin: Vector3, bmax: Vector3) -> bool:
	var half := size * 0.5
	return (center.x - half.x >= bmin.x - 0.001 and center.x + half.x <= bmax.x + 0.001
		and center.y - half.y >= bmin.y - 0.001 and center.y + half.y <= bmax.y + 0.001
		and center.z - half.z >= bmin.z - 0.001 and center.z + half.z <= bmax.z + 0.001)


func _point_in_box(p: Vector3, center: Vector3, size: Vector3) -> bool:
	var half := size * 0.5
	return (abs(p.x - center.x) <= half.x
		and abs(p.y - center.y) <= half.y
		and abs(p.z - center.z) <= half.z)
