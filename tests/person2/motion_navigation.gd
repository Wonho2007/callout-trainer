extends Node3D
# Explicit test double for failure paths; real Person 1 bake tested separately.
var navigation_is_ready: bool = true
var mode: String = "direct"
func query_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	match mode:
		"empty": return PackedVector3Array()
		"partial": return PackedVector3Array([from, to + Vector3(2, 0, 0)])
		"offmesh": return PackedVector3Array([from + Vector3(2, 0, 0), to])
		"nan": return PackedVector3Array([from, Vector3(NAN, 0, 0)])
	return PackedVector3Array([from, to])
