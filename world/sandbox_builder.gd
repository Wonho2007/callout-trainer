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

@export_file("*.json") var map_path: String = "res://world/maps/b_site.json"
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
	for divot in m.get("divots", []):
		# Stair/circular divots are built as part of the CSG floor-pit (collision + surface);
		# skip the legacy per-divot mesh so there is no competing collision.
		if String(divot.get("shape", "ramp")) == "stairs":
			continue
		_build_divot(divot, nav_region)

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

	# Divots carve a square gap out of the floor so their recessed ramp/bottom
	# (built by _build_divot) is exposed and walkable. Use plain box floor
	# segments around each gap — box collision is reliable (no fragile trimesh).
	var gaps: Array = []
	for divot in m.get("divots", []):
		var c := _to_vec3(divot.get("center", [0, 0, 0]))
		# Gap half-size = the divot's TOP radius so the recessed shape sits in the open
		# gap (walkable, floor doesn't block it). For a conical ramp the top extends
		# depth*RAMP_RUN_FACTOR past the bottom radius; for stairs the caller gives the
		# outer (rim) radius directly via top_radius.
		var r: float
		if String(divot.get("shape", "ramp")) == "stairs":
			r = float(divot.get("top_radius", divot.get("radius", 2.0) + 4.0))
		else:
			r = float(divot.get("radius", 2.0)) + float(divot.get("depth", 0.9)) * RAMP_RUN_FACTOR
		gaps.append({"x": c.x, "z": c.z, "half": r})

	if gaps.is_empty():
		var floor_box := {
			"id": "floor",
			"position": [0, fy - 0.05, 0],
			"size": [fx, 0.1, fz],
		}
		_build_solid_box(floor_box, parent, Color(0.30, 0.31, 0.34))
		return

	# Circular (stair/cone) divot: build the floor AND the pit void as ONE CSG solid so Godot
	# generates the hole and its collision (no hand-built trimesh seam at the rim, which was
	# where the capsule clipped in). The CSG combiner carries use_collision = true.
	var circular: Dictionary = {}
	for divot in m.get("divots", []):
		var c := _to_vec3(divot.get("center", [0, 0, 0]))
		circular = {
			"x": c.x, "z": c.z,
			"top_radius": float(divot.get("top_radius", 5.5)),
			"bottom_radius": float(divot.get("radius", 1.0)),
			"depth": float(divot.get("depth", 3.0)),
		}
		break  # one divot supported here
	if not circular.is_empty():
		_build_csg_floor_pit(fx, fz, fy, circular, parent, Color(0.30, 0.31, 0.34))
		return

	# (Legacy square-gap path kept for any non-circular future divot shapes.)
	var g: Dictionary = gaps[0]
	var gx := float(g["x"])
	var gz := float(g["z"])
	var gh := float(g["half"])
	var xmin := -fx * 0.5
	var xmax := fx * 0.5
	var zmin := -fz * 0.5
	var zmax := fz * 0.5
	var gx0 := gx - gh
	var gx1 := gx + gh
	var gz0 := gz - gh
	var gz1 := gz + gh
	var col := Color(0.30, 0.31, 0.34)
	# North strip (z < gz0), full width.
	_floor_slab("floor_n", xmin, xmax, zmin, gz0, fy, parent, col)
	# South strip (z > gz1), full width.
	_floor_slab("floor_s", xmin, xmax, gz1, zmax, fy, parent, col)
	# West strip beside the gap.
	_floor_slab("floor_w", xmin, gx0, gz0, gz1, fy, parent, col)
	# East strip beside the gap.
	_floor_slab("floor_e", gx1, xmax, gz0, gz1, fy, parent, col)
	# Solid cap across the whole gap at the pit's bottom depth, so a player can
	# never fall through a corner where the square gap exceeds the round pit —
	# they land on pit floor instead of the void.
	var pit_depth := 0.9
	for divot in m.get("divots", []):
		pit_depth = float(divot.get("depth", 0.9))
	_floor_slab("floor_pit_cap", gx0, gx1, gz0, gz1, fy - pit_depth, parent, Color(0.24, 0.25, 0.29))


## Build one rectangular floor slab spanning [x0..x1] x [z0..z1] at height y.
func _floor_slab(id: String, x0: float, x1: float, z0: float, z1: float, y: float, parent: Node3D, color: Color) -> void:
	var w := x1 - x0
	var d := z1 - z0
	if w <= 0.01 or d <= 0.01:
		return
	var box := {
		"id": id,
		"position": [(x0 + x1) * 0.5, y - 0.05, (z0 + z1) * 0.5],
		"size": [w, 0.1, d],
	}
	_build_solid_box(box, parent, color)


## Continuous floor covering the whole rectangle EXCEPT a circular hole of radius `hole_r`
## centered at (cx,cz). Built in two parts: (1) plain box slabs filling the rectangle outside
## a square that bounds the circle, and (2) a procedural "square-with-round-hole" ring mesh
## (+ trimesh collision) for the band between the circle and that square. No gaps at the
## corners, and nothing is placed inside the circle (the divot mesh fills it) -> no z-fighting.
func _build_floor_with_hole(fx: float, fz: float, fy: float, cx: float, cz: float,
		hole_r: float, parent: Node3D, color: Color) -> void:
	var xmin := -fx * 0.5
	var xmax := fx * 0.5
	var zmin := -fz * 0.5
	var zmax := fz * 0.5
	# Square that bounds the circle (side = 2*hole_r), centered on the hole.
	var sx0 := cx - hole_r
	var sx1 := cx + hole_r
	var sz0 := cz - hole_r
	var sz1 := cz + hole_r
	# (1) Four plain slabs filling the rectangle outside that bounding square.
	_floor_slab("floor_n", xmin, xmax, zmin, sz0, fy, parent, color)   # north of the square
	_floor_slab("floor_s", xmin, xmax, sz1, zmax, fy, parent, color)   # south of the square
	_floor_slab("floor_w", xmin, sx0, sz0, sz1, fy, parent, color)     # west band
	_floor_slab("floor_e", sx1, xmax, sz0, sz1, fy, parent, color)     # east band

	# (2) Square-with-round-hole ring between the circle (radius hole_r) and the bounding
	# square edge. For each angular segment, connect a point on the circle to the matching
	# point on the square perimeter, triangulated so the band is solid.
	var body := StaticBody3D.new()
	body.name = "floor_hole_ring"
	body.position = Vector3(cx, fy - 0.05, cz)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	parent.add_child(body)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 64
	for i in range(segs):
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		# inner points on the circle
		var inr0 := Vector3(cos(a0) * hole_r, 0, sin(a0) * hole_r)
		var inr1 := Vector3(cos(a1) * hole_r, 0, sin(a1) * hole_r)
		# outer points on the square perimeter (ray from center to square edge)
		var out0 := _square_edge_point(cos(a0), sin(a0), hole_r)
		var out1 := _square_edge_point(cos(a1), sin(a1), hole_r)
		# two triangles forming the quad (inr0, out0, out1, inr1); wind to face up (+Y)
		st.add_vertex(inr0); st.add_vertex(out0); st.add_vertex(out1)
		st.add_vertex(inr0); st.add_vertex(out1); st.add_vertex(inr1)
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	body.add_child(mi)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)


## Point where a ray (dirx,dirz) from the center hits the edge of a square of half-size `half`.
func _square_edge_point(dirx: float, dirz: float, half: float) -> Vector3:
	var ax := absf(dirx)
	var az := absf(dirz)
	var t: float
	if ax >= az:
		t = half / maxf(ax, 0.0001)
	else:
		t = half / maxf(az, 0.0001)
	return Vector3(dirx * t, 0, dirz * t)


## A walk-in circular divot: a recessed flat bottom with a gentle sloped conical
## ramp so the player can walk down into it and back OUT without sliding or
## jumping. The ramp run is wider than the depth (shallow ~22-degree slope).
## `radius` = flat bottom radius; `depth` = how deep; the top rim extends
## depth*RAMP_RUN_FACTOR further out. Built as a procedural mesh + trimesh
## collision. The top rim overlaps the floor gap so there are no seams.
const RAMP_RUN_FACTOR := 2.5

func _build_csg_floor_pit(fx: float, fz: float, fy: float, pit: Dictionary,
		parent: Node3D, color: Color) -> void:
	var cx := float(pit["x"])
	var cz := float(pit["z"])
	var top_r := float(pit["top_radius"])
	var bot_r := float(pit["bottom_radius"])
	var depth := float(pit["depth"])
	var slab_thick := depth + 2.0            # floor block thick enough to contain the pit

	var combiner := CSGCombiner3D.new()
	combiner.name = "floor_pit_csg"
	combiner.use_collision = true
	combiner.collision_layer = LAYER_WORLD
	combiner.collision_mask = 0
	# Place so the slab TOP is at y = fy (floor surface at 0).
	combiner.position = Vector3(0, fy - slab_thick * 0.5, 0)
	parent.add_child(combiner)

	# Floor slab (union).
	var slab := CSGBox3D.new()
	slab.name = "slab"
	slab.size = Vector3(fx, slab_thick, fz)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = color
	slab.material = smat
	combiner.add_child(slab)

	# Pit void: a lathed cone profile, subtracted. The slab center is at local y=0, so the
	# slab TOP is at +slab_thick/2. Carve from the top surface down `depth`.
	var top_y := slab_thick * 0.5
	var cut := CSGPolygon3D.new()
	cut.name = "pit_void"
	cut.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut.mode = CSGPolygon3D.MODE_SPIN
	cut.spin_degrees = 360.0
	cut.spin_sides = 64
	cut.position = Vector3(cx, 0, cz)             # center the lathe on the pit
	# 2D profile revolved around the local Y axis (x = radius). Enclosed area = the void:
	# rim (top) -> cone wall down to the flat-bottom edge -> flat bottom to the axis -> up.
	var prof := PackedVector2Array([
		Vector2(top_r, top_y + 0.1),
		Vector2(bot_r, top_y - depth),
		Vector2(0.0,   top_y - depth),
		Vector2(0.0,   top_y + 0.1),
	])
	cut.polygon = prof
	combiner.add_child(cut)


func _build_divot(divot: Dictionary, parent: Node3D) -> void:
	var id := String(divot.get("id", "divot"))
	var center := _to_vec3(divot.get("center", [0, 0, 0]))

	if String(divot.get("shape", "ramp")) == "stairs":
		_build_stair_pit(divot, parent)
		return

	var bottom_radius := float(divot.get("radius", 2.0))
	var depth := float(divot.get("depth", 0.9))
	# Gentle walkable ramp: run is wider than the drop (~22 degrees).
	var top_radius := bottom_radius + depth * RAMP_RUN_FACTOR
	var segments := 48

	var body := StaticBody3D.new()
	body.name = id
	body.position = Vector3(center.x, 0.0, center.z)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	parent.add_child(body)

	# Build the surface: flat bottom disc at y=-depth + a conical ramp wall from
	# the top rim (y=0, top_radius) down to the bottom edge (y=-depth, bottom_radius).
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bottom_center := Vector3(0, -depth, 0)
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var top0 := Vector3(cos(a0) * top_radius, 0.0, sin(a0) * top_radius)
		var top1 := Vector3(cos(a1) * top_radius, 0.0, sin(a1) * top_radius)
		var bot0 := Vector3(cos(a0) * bottom_radius, -depth, sin(a0) * bottom_radius)
		var bot1 := Vector3(cos(a1) * bottom_radius, -depth, sin(a1) * bottom_radius)
		# Ramp wall (two triangles per segment), wound to face up/inward.
		st.add_vertex(top0); st.add_vertex(bot0); st.add_vertex(top1)
		st.add_vertex(top1); st.add_vertex(bot0); st.add_vertex(bot1)
		# Flat bottom fan.
		st.add_vertex(bot0); st.add_vertex(bottom_center); st.add_vertex(bot1)
	st.generate_normals()
	var mesh := st.commit()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.25, 0.29)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # visible from inside the pit
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	# Matching collision from the same surface so the player walks the ramp/floor.
	var collision := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	collision.shape = shape
	body.add_child(collision)


## A walk-in STAIR pit: concentric circular steps descending to a flat bottom disc.
## `top_radius` = rim radius (where the stairs begin at y=0); `radius` = flat bottom disc
## radius (the slightly-flattened deep floor so it is not pointy); `depth` = total drop;
## `steps` = number of equal steps. Each step is a horizontal tread ring + a vertical
## riser. Built as one procedural mesh + trimesh collision so the player walks in/out.
func _build_stair_pit(divot: Dictionary, parent: Node3D) -> void:
	var id := String(divot.get("id", "pit"))
	var center := _to_vec3(divot.get("center", [0, 0, 0]))
	var top_radius := float(divot.get("top_radius", 6.0))
	var bottom_radius := float(divot.get("radius", 2.0))
	var depth := float(divot.get("depth", 3.0))
	var steps := int(divot.get("steps", 6))
	var segments := 48

	var body := StaticBody3D.new()
	body.name = id
	body.position = Vector3(center.x, 0.0, center.z)
	body.collision_layer = LAYER_WORLD
	body.collision_mask = 0
	parent.add_child(body)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var riser := depth / float(steps)                       # vertical drop per step (0.5 m)
	var run := (top_radius - bottom_radius) / float(steps)   # radial width per tread

	# Build each step: a tread (flat ring) at its depth, then a riser (vertical ring wall)
	# dropping to the next step. Step k spans radius [top_radius - k*run .. top_radius-(k+1)*run].
	for k in range(steps):
		var r_outer := top_radius - run * float(k)
		var r_inner := top_radius - run * float(k + 1)
		var y_tread := -riser * float(k)         # tread top surface height
		var y_next := -riser * float(k + 1)      # next tread height (bottom of this riser)
		for i in range(segments):
			var a0 := TAU * float(i) / float(segments)
			var a1 := TAU * float(i + 1) / float(segments)
			var co0 := Vector3(cos(a0), 0, sin(a0))
			var co1 := Vector3(cos(a1), 0, sin(a1))
			# Flat tread ring at y_tread, from r_inner to r_outer.
			var to0 := co0 * r_outer + Vector3(0, y_tread, 0)
			var to1 := co1 * r_outer + Vector3(0, y_tread, 0)
			var ti0 := co0 * r_inner + Vector3(0, y_tread, 0)
			var ti1 := co1 * r_inner + Vector3(0, y_tread, 0)
			st.add_vertex(to0); st.add_vertex(ti0); st.add_vertex(to1)
			st.add_vertex(to1); st.add_vertex(ti0); st.add_vertex(ti1)
			# Vertical riser at r_inner, from y_tread down to y_next.
			var ru0 := co0 * r_inner + Vector3(0, y_tread, 0)
			var ru1 := co1 * r_inner + Vector3(0, y_tread, 0)
			var rd0 := co0 * r_inner + Vector3(0, y_next, 0)
			var rd1 := co1 * r_inner + Vector3(0, y_next, 0)
			st.add_vertex(ru0); st.add_vertex(rd0); st.add_vertex(ru1)
			st.add_vertex(ru1); st.add_vertex(rd0); st.add_vertex(rd1)

	# Flat bottom disc (slightly-flattened deep floor, not pointy) at y = -depth.
	var bottom_center := Vector3(0, -depth, 0)
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var b0 := Vector3(cos(a0) * bottom_radius, -depth, sin(a0) * bottom_radius)
		var b1 := Vector3(cos(a1) * bottom_radius, -depth, sin(a1) * bottom_radius)
		st.add_vertex(b0); st.add_vertex(bottom_center); st.add_vertex(b1)

	st.generate_normals()
	var mesh := st.commit()

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.24, 0.25, 0.29)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	# Collision: a single clean SMOOTH cone (rim at top_radius/y=0 -> flat bottom disc at
	# -depth), no overlap, no steps, no stacked shapes. With a gentle slope (< floor_max_angle)
	# plain move_and_slide walks the capsule straight in and out. The stepped mesh above is
	# visual only. Keeping this dead simple after stepped/overlap/cylinder variants all fought
	# the CharacterBody3D.
	var cst := SurfaceTool.new()
	cst.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c_bottom := Vector3(0, -depth, 0)
	for i in range(segments):
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var t0 := Vector3(cos(a0) * top_radius, 0.0, sin(a0) * top_radius)
		var t1 := Vector3(cos(a1) * top_radius, 0.0, sin(a1) * top_radius)
		var bd0 := Vector3(cos(a0) * bottom_radius, -depth, sin(a0) * bottom_radius)
		var bd1 := Vector3(cos(a1) * bottom_radius, -depth, sin(a1) * bottom_radius)
		cst.add_vertex(t0); cst.add_vertex(bd0); cst.add_vertex(t1)
		cst.add_vertex(t1); cst.add_vertex(bd0); cst.add_vertex(bd1)
		cst.add_vertex(bd0); cst.add_vertex(c_bottom); cst.add_vertex(bd1)
	cst.generate_normals()
	var cmesh := cst.commit()
	var collision := CollisionShape3D.new()
	collision.shape = cmesh.create_trimesh_shape()
	body.add_child(collision)


func _build_solid_box(box: Dictionary, parent: Node3D, color: Color = Color(0.6, 0.6, 0.62)) -> void:
	var id := String(box.get("id", "box"))
	var pos := _to_vec3(box.get("position", [0, 0, 0]))
	var size := _to_vec3(box.get("size", [1, 1, 1]))

	var body := StaticBody3D.new()
	body.name = id
	body.position = pos
	# Optional rotation (degrees, XYZ) — used for tilted-box ramps. A solid rotated box is a
	# convex collider, so a CharacterBody3D walks its sloped face cleanly (no trimesh needed).
	if box.has("rotation_deg"):
		var rd := _to_vec3(box.get("rotation_deg", [0, 0, 0]))
		body.rotation = Vector3(deg_to_rad(rd.x), deg_to_rad(rd.y), deg_to_rad(rd.z))
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
	if String(region.get("shape", "box")) == "circle":
		var cyl := CylinderShape3D.new()
		cyl.radius = float(region.get("radius", 1.0))
		cyl.height = size.y
		collision.shape = cyl
	else:
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
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	lighting.add_child(sun)

	# A dimmer fill light from the opposite side so faces that point away from
	# the sun still get some shading contrast (helps larger spaces read).
	var fill := DirectionalLight3D.new()
	fill.name = "Fill"
	fill.rotation_degrees = Vector3(-30, 150, 0)
	fill.light_energy = 0.5
	fill.shadow_enabled = false
	lighting.add_child(fill)

	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.20, 0.22, 0.26)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.48, 0.55)
	e.ambient_light_energy = 0.3
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


## Top-down (XZ) map overlay as plain, serializable data for Person 3's debrief
## minimap. Static map layout is public (brief §6.4), so this is not privileged
## truth. All rects are {id, x, z, w, d}: x/z = center on the top-down plane,
## w/d = full width (X) and depth (Z). Regions add name; spawns add role.
## Person 3 renders this; it needs no 3D scene access.
func get_map_overlay() -> Dictionary:
	var overlay := {
		"map_id": map_data.get("id", ""),
		"bounds": {
			"min": map_data.get("bounds", {}).get("min", [-10, 0, -10]),
			"max": map_data.get("bounds", {}).get("max", [10, 4, 10]),
		},
		"walls": [],
		"cover": [],
		"regions": [],
		"spawns": [],
		"spike": null,
	}
	for wall in map_data.get("walls", []):
		overlay["walls"].append(_rect_xz(wall))
	for box in map_data.get("cover", []):
		overlay["cover"].append(_rect_xz(box))
	for region in map_data.get("regions", []):
		var r := {
			"id": region.get("id", ""),
			"name": region.get("name", region.get("id", "")),
			"shape": region.get("shape", "box"),
		}
		var c := _to_vec3(region.get("center", [0, 0, 0]))
		var s := _to_vec3(region.get("size", [1, 1, 1]))
		r["x"] = c.x
		r["z"] = c.z
		r["w"] = s.x
		r["d"] = s.z
		r["radius"] = float(region.get("radius", 0.0))
		overlay["regions"].append(r)
	for spawn in map_data.get("spawns", []):
		var p := _to_vec3(spawn.get("position", [0, 0, 0]))
		overlay["spawns"].append({
			"id": spawn.get("id", ""),
			"role": spawn.get("role", ""),
			"x": p.x,
			"z": p.z,
		})
	if map_data.has("spike"):
		var sp := _to_vec3(map_data["spike"].get("position", [0, 0, 0]))
		overlay["spike"] = {"x": sp.x, "z": sp.z}
	return overlay


## A box's top-down rect {id, x, z, w, d} from its position(center) and size.
func _rect_xz(box: Dictionary) -> Dictionary:
	var pos := _to_vec3(box.get("position", [0, 0, 0]))
	var size := _to_vec3(box.get("size", [1, 1, 1]))
	return {"id": box.get("id", ""), "x": pos.x, "z": pos.z, "w": size.x, "d": size.z}


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
