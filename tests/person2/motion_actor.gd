extends Node3D
# Test double, NOT shared movement mechanics.
var is_alive: bool = true
var move_dir: Vector3 = Vector3.ZERO
var move_calls: int = 0
func set_move_dir(direction: Vector3) -> void:
	move_dir = direction
func move_toward_point(point: Vector3) -> float:
	move_calls += 1
	move_dir = point - global_position
	return move_dir.length()
