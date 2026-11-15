extends "res://bots/flash_controller.gd"
# Privileged physical adapter: own pose + static zone points + world/smoke LOS.
# No opponent references, live enemy positions, or policy-controlled coordinates.
var _look_points: Dictionary = {}
var _selected_points: Dictionary = {}

func _init(actor: Node3D, utility: Node3D, targets: Dictionary, markers: Dictionary, charges: int) -> void:
	super(actor, utility, {}, markers, 0)
	if not Data.valid(targets) or not Data.valid(markers) or charges < 0:
		return
	for id in targets:
		var target: Variant = targets[id]
		if not Data.nonempty(id) or not target is Dictionary or not Data.keys_exact(target, ["stage_marker_id", "target_marker_id", "aim_points", "max_range_m"]):
			return
		if not target.stage_marker_id is String or not target.target_marker_id is String or target.stage_marker_id not in markers or target.target_marker_id not in markers or not target.aim_points is Array or target.aim_points.is_empty():
			return
		if not (target.max_range_m is int or target.max_range_m is float) or not is_finite(float(target.max_range_m)) or target.max_range_m <= 0:
			return
		for point in target.aim_points:
			if not point is Array or point.size() != 3 or not point.all(func(n: Variant): return (n is int or n is float) and is_finite(float(n))):
				return
	_targets = targets.duplicate(true)
	_markers = markers.duplicate(true)
	_remaining = charges

func uses_visibility(target_id: String) -> bool:
	return _targets.has(target_id)

func _vec(point: Array) -> Vector3:
	return Vector3(point[0], point[1], point[2])

func _turn(point: Vector3) -> bool:
	var direction: Vector3 = point - (_actor.global_position + Vector3.UP * 1.6)
	if Vector2(direction.x, direction.z).length() < 0.01:
		return true
	var desired: float = atan2(-direction.x, -direction.z)
	_actor.rotation.y += clampf(angle_difference(_actor.rotation.y, desired), -TAU / Engine.physics_ticks_per_second, TAU / Engine.physics_ticks_per_second)
	return absf(angle_difference(_actor.rotation.y, desired)) <= deg_to_rad(3.0)

func _clear(origin: Vector3, point: Vector3) -> bool:
	if _utility != null and _utility.segment_blocked_by_smoke(origin, point):
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, point, 1)
	return _actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func prepare_visible(target_id: String) -> Dictionary:
	if not is_instance_valid(_actor) or not _actor.is_alive:
		return {"state": "failed", "reason": "actor_dead"}
	if not _targets.has(target_id):
		return {"state": "failed", "reason": "unknown_flash_target"}
	if _remaining <= 0:
		return {"state": "failed", "reason": "no_utility"}
	if _actor.get_meta("bot_blinded", false):
		return {"state": "paused", "reason": "blinded"}
	var target: Dictionary = _targets[target_id]
	var origin: Vector3 = _actor.global_position + Vector3.UP * 1.6
	var center: Vector3 = _vec(_markers[target.target_marker_id].position) + Vector3.UP * 1.5
	if not _look_points.has(target_id):
		_look_points[target_id] = center
	# Turning is completed before a blocked zone can authorize any walking.
	if not _turn(_look_points[target_id]):
		return {"state": "turning", "reason": "looking_toward_flash_zone"}
	var candidates: Array = target.aim_points.duplicate(true)
	candidates.sort_custom(func(a: Array, b: Array): return origin.distance_squared_to(_vec(a)) < origin.distance_squared_to(_vec(b)))
	var visible_but_far: bool = false
	for candidate in candidates:
		var point: Vector3 = _vec(candidate)
		var distance: float = origin.distance_to(point)
		if distance < 0.5 or not _clear(origin, point):
			continue
		if distance > float(target.max_range_m):
			visible_but_far = true
			continue
		_look_points[target_id] = point
		if not _turn(point):
			return {"state": "turning", "reason": "aiming_visible_flash_zone"}
		_selected_points[target_id] = point
		return {"state": "ready", "reason": "flash_zone_visible"}
	_selected_points.erase(target_id)
	_look_points[target_id] = center
	if visible_but_far:
		return {"state": "failed", "reason": "visible_zone_out_of_throw_range"}
	return {"state": "blocked", "reason": "flash_zone_occluded"}

func launch(command_id: String, target_id: String) -> Dictionary:
	if _released.has(command_id):
		return _released[command_id].duplicate(true)
	var readiness: Dictionary = prepare_visible(target_id)
	if readiness.state != "ready" or not is_instance_valid(_utility):
		_released[command_id] = {"ok": false, "reason": readiness.reason if readiness.state != "ready" else "utility_adapter_unavailable"}
		return _released[command_id].duplicate(true)
	_remaining -= 1
	_released[command_id] = {"ok": false, "reason": "launch_in_progress"}
	var origin: Vector3 = _actor.global_position + Vector3.UP * 1.6
	var flight: float = 0.6
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var velocity: Vector3 = (_selected_points[target_id] - origin) / flight + Vector3.UP * gravity * flight * 0.5
	var effect: Node3D = _utility.throw_flash(origin, velocity)
	if not is_instance_valid(effect):
		_remaining += 1
		_released[command_id] = {"ok": false, "reason": "physical_launch_failed"}
	else:
		_released[command_id] = {"ok": true, "reason": "projectile_released"}
	return _released[command_id].duplicate(true)
