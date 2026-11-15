extends "res://world/sandbox_builder.gd"
# Optional authored ramp geometry before the inherited navigation bake.
# This leaves the shared default builder/maps unchanged.

func _build_floor(map: Dictionary, parent: Node3D) -> void:
	super._build_floor(map, parent)
	# Keep the inherited safety collision cap, but don't bake its hidden,
	# overlapping flat mesh underneath the actual conical pit surface.
	var cap: Node = parent.get_node_or_null("floor_pit_cap")
	if cap != null:
		for child in cap.get_children():
			if child is MeshInstance3D:
				child.reparent(self, true)
				child.name = "PitSafetyVisual"
	for ramp in map.get("ramps", []):
		_build_ramp(ramp, parent)

func _build_ramp(ramp: Dictionary, parent: Node3D) -> void:
	var size := Vector3(ramp.size[0], ramp.size[1], ramp.size[2])
	var w: float = size.x / 2.0
	var z: float = size.z / 2.0
	var vertices: Array[Vector3] = [Vector3(-w, 0, z), Vector3(w, 0, z), Vector3(w, size.y, -z), Vector3(-w, size.y, -z),
		Vector3(-w, -0.2, z), Vector3(w, -0.2, z), Vector3(w, -0.2, -z), Vector3(-w, -0.2, -z)]
	var triangles: Array = [[0, 1, 2], [0, 2, 3], [1, 5, 6], [1, 6, 2], [3, 2, 6], [3, 6, 7],
		[0, 3, 7], [0, 7, 4], [0, 4, 5], [0, 5, 1], [4, 7, 6], [4, 6, 5]]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in triangles:
		for index in [triangle[2], triangle[1], triangle[0]]:
			surface.add_vertex(vertices[index])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	var body := StaticBody3D.new()
	body.name = ramp.id
	body.position = Vector3(ramp.position[0], ramp.position[1], ramp.position[2])
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.4, 0.45, 0.5)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	body.add_child(collision)

func _clear_generated() -> void:
	var safety: Node = get_node_or_null("PitSafetyVisual")
	if safety != null:
		safety.free()
	super._clear_generated()

func _build_divot(divot: Dictionary, parent: Node3D) -> void:
	super._build_divot(divot, parent)
	var body: Node = parent.get_node(NodePath(str(divot.id)))
	var visual: MeshInstance3D = body.get_child(0)
	var faces: PackedVector3Array = visual.mesh.get_faces()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(0, faces.size(), 3):
		for offset in [2, 1, 0]:
			surface.add_vertex(faces[index + offset])
	surface.generate_normals()
	var mesh: ArrayMesh = surface.commit()
	visual.mesh = mesh
	var collision: CollisionShape3D = body.get_child(1)
	collision.shape = mesh.create_trimesh_shape()
