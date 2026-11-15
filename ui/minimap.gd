extends Control
class_name Minimap
## Top-down minimap HUD (Person 1).
##
## Draws the static map overlay (walls/cover/regions/spike) from the builder's
## get_map_overlay(), the player as a dot with a facing view-cone wedge, and any
## enemy currently INSIDE the player's view cone with clear line of sight.
##
## Fairness: this renders only what the player can actually see. An enemy outside
## the cone, out of range, or behind a wall is not drawn — the minimap shows the
## player's own perception, not hidden positions. It is a player HUD aid, not a
## bot-policy input.

## World-to-minimap scale is computed from the map bounds to fit the panel.
@export var fov_degrees: float = 100.0
@export var view_range_m: float = 40.0

var builder: Node          # SandboxBuilder (has get_map_overlay)
var player: Node3D         # the player actor
var enemies: Array = []    # enemy ActorBase nodes to test against the cone

var _overlay: Dictionary = {}
var _world_min := Vector2(-10, -10)
var _world_max := Vector2(10, 10)


func _ready() -> void:
	pass  # Overlay is refreshed by the owner (main) once builder/player are set.


## Called by the owner after builder/player are assigned.
func refresh() -> void:
	_refresh_overlay()


func _refresh_overlay() -> void:
	if builder and builder.has_method("get_map_overlay"):
		_overlay = builder.get_map_overlay()
		var bmin = _overlay.get("bounds", {}).get("min", [-10, 0, -10])
		var bmax = _overlay.get("bounds", {}).get("max", [10, 4, 10])
		_world_min = Vector2(float(bmin[0]), float(bmin[2]))
		_world_max = Vector2(float(bmax[0]), float(bmax[2]))
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


## Map a world XZ point to a pixel inside this control's rect.
func _to_map(wx: float, wz: float) -> Vector2:
	var sz := size
	var span := _world_max - _world_min
	if span.x <= 0.001 or span.y <= 0.001:
		return Vector2.ZERO
	var u := (wx - _world_min.x) / span.x
	var v := (wz - _world_min.y) / span.y
	return Vector2(u * sz.x, v * sz.y)


func _draw() -> void:
	# Background panel.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.11, 0.85))

	if _overlay.is_empty():
		return

	# Cover, then walls (callout regions are not drawn on the live minimap).
	for c in _overlay.get("cover", []):
		_draw_world_rect(c, Color(0.9, 0.55, 0.3, 0.6))
	for w in _overlay.get("walls", []):
		_draw_world_rect(w, Color(0.75, 0.78, 0.85, 0.8))

	# Spike.
	var spike = _overlay.get("spike", null)
	if spike != null:
		draw_circle(_to_map(float(spike["x"]), float(spike["z"])), 3.0, Color(0.9, 0.2, 0.15))

	if player == null:
		return

	var ppos := player.global_position
	var pp := _to_map(ppos.x, ppos.z)
	var forward := -player.global_transform.basis.z
	var yaw := atan2(forward.x, forward.z)  # world heading on XZ

	# View-cone wedge.
	_draw_view_cone(pp, yaw)

	# Player dot.
	draw_circle(pp, 4.0, Color(0.3, 0.8, 1.0))

	# Enemies the player can actually see (in cone + line of sight).
	for e in enemies:
		if e == null or not is_instance_valid(e):
			continue
		if _player_can_see(ppos, forward, e.global_position):
			draw_circle(_to_map(e.global_position.x, e.global_position.z), 4.0,
				Color(1.0, 0.3, 0.3))


func _draw_world_rect(rect: Dictionary, color: Color) -> void:
	var cx := float(rect.get("x", 0.0))
	var cz := float(rect.get("z", 0.0))
	var w := float(rect.get("w", 1.0))
	var d := float(rect.get("d", 1.0))
	var top_left := _to_map(cx - w * 0.5, cz - d * 0.5)
	var bot_right := _to_map(cx + w * 0.5, cz + d * 0.5)
	draw_rect(Rect2(top_left, bot_right - top_left), color)


func _draw_view_cone(origin: Vector2, yaw: float) -> void:
	var half := deg_to_rad(fov_degrees * 0.5)
	# Cone length in pixels, scaled from view_range in world units.
	var span := _world_max - _world_min
	var px_per_m := size.x / maxf(0.001, span.x)
	var length := view_range_m * px_per_m
	# On the minimap, +x is world x and +y is world z. yaw = atan2(fx, fz).
	var dir := Vector2(sin(yaw), cos(yaw))
	var left := dir.rotated(-half)
	var right := dir.rotated(half)
	var pts := PackedVector2Array([
		origin,
		origin + left * length,
		origin + right * length,
	])
	draw_colored_polygon(pts, Color(0.3, 0.8, 1.0, 0.15))


## True if `target` is within the player's FOV cone, in range, and has clear
## line of sight (not through world geometry). Mirrors the player's perception.
func _player_can_see(eye: Vector3, forward: Vector3, target: Vector3) -> bool:
	# Compare on the horizontal plane for FOV/range (ignore height difference).
	var flat_to := Vector3(target.x - eye.x, 0.0, target.z - eye.z)
	var dist := flat_to.length()
	if dist > view_range_m or dist < 0.001:
		return false
	var dir := flat_to / dist
	var fwd := forward
	fwd.y = 0.0
	fwd = fwd.normalized()
	# Within the FOV half-angle?
	if fwd.dot(dir) < cos(deg_to_rad(fov_degrees * 0.5)):
		return false
	# Line of sight at realistic heights: from the player's eye to the target's
	# torso, so cover at chest height actually blocks the sightline.
	if player == null:
		return false
	var eye_pos := eye + Vector3(0, 1.6, 0)
	var torso := Vector3(target.x, target.y + 1.0, target.z)
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(eye_pos, torso)
	query.collision_mask = 1 << 0  # world geometry only
	if player is CollisionObject3D:
		query.exclude = [player.get_rid()]
	var hit := space.intersect_ray(query)
	return hit.is_empty()
