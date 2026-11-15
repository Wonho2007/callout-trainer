extends RefCounted
# PRIVILEGED perception boundary. Physics/nav handles and exact geometry stay
# here; only delayed, JSON-compatible observations may leave for bot policy.
const Data = preload("res://perception/plain_data.gd")
var _bot_id: String
var _config: Dictionary = {}
var _configured: bool = false
var _clock: int = -1
var _serial: int = 0
var _rng := RandomNumberGenerator.new()
var _tracking: Dictionary = {}
var _sound_records: Dictionary = {}

# PRIVILEGED adapter-only diagnostic for the last successful sample. These IDs
# precede reaction delay and must never be exposed directly to policy/model.
# SceneSensor uses it only to enqueue delayed loss of a previously observed aim.
func sampled_visible_ids() -> Array:
	return _tracking.keys().duplicate()

func _init(bot_id: String, configuration: Dictionary, seed_value: int) -> void:
	_bot_id = bot_id
	_rng.seed = seed_value
	if Data.nonempty(bot_id) and Data.valid(configuration):
		_config = configuration.duplicate(true)
		_configured = _valid_config()

# Call only inside a physics callback with current-frame inputs. Never give the
# caller's privileged descriptors, this object, or pending output to policy.
func sample(tick: int, observer: Dictionary, targets: Array, sounds: Array,
		space: PhysicsDirectSpaceState3D, navigation_map: RID = RID()) -> Dictionary:
	if not _configured:
		return _error("invalid_configuration")
	if not Data.integer(tick) or tick > 2147483647 - _config.delay_max_ticks:
		return _error("invalid_tick")
	if tick <= _clock:
		return _error("non_monotonic_tick")
	if space == null or not _valid_observer(observer):
		return _error("invalid_observer_or_space")
	if not _valid_targets(targets, observer.exclude_rids):
		return _error("invalid_targets")
	if not _valid_sounds(sounds, tick):
		return _error("invalid_sounds")
	if _needs_navigation(observer, sounds):
		if not navigation_map.is_valid() or navigation_map not in NavigationServer3D.get_maps() or NavigationServer3D.map_get_iteration_id(navigation_map) == 0:
			return _error("navigation_not_ready")
	# All input validation precedes state mutation or random draws.
	var observations: Array = []
	var next_tracking: Dictionary = {}
	var ordered_targets: Array = targets.duplicate()
	ordered_targets.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.enemy_id < b.enemy_id)
	if observer.alive and tick >= observer.blind_until_tick:
		for target in ordered_targets:
			var distance: float = _visible_distance(observer, target, space)
			if not is_finite(distance):
				continue
			var track: Dictionary = _tracking.get(target.enemy_id, {})
			if track.is_empty() or track.last_tick != tick - 1:
				track = {"start_tick": tick, "last_tick": tick, "reported": false,
					"last_region": "", "last_emit_tick": -1}
			else:
				track = track.duplicate(true)
			track.last_tick = tick
			var exposure: int = int(_config.near_exposure_ticks if distance <= _config.near_range else _config.far_exposure_ticks)
			if tick - track.start_tick >= exposure:
				if not track.reported or track.last_region != target.region_id or tick - track.last_emit_tick >= _config.refresh_ticks:
					observations.append(_observation(tick, "seen",
						{"type": "enemy_seen", "enemy_id": target.enemy_id, "region_id": target.region_id}))
					track.reported = true
					track.last_region = target.region_id
					track.last_emit_tick = tick
			next_tracking[target.enemy_id] = track
	var ordered_sounds: Array = sounds.duplicate()
	ordered_sounds.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for event in ordered_sounds:
		_sound_records[event.id] = event.duplicate(true)
		var radius: float = float(_config.sound_radii[event.kind])
		if not observer.alive or radius <= 0.0:
			continue
		var distance: float = _path_distance(observer.position, event.position, navigation_map)
		if distance <= radius:
			observations.append(_observation(tick, "heard", {"type": "sound_heard", "sound_kind": event.kind,
				"distance_class": "near" if distance <= _config.hearing_near_distance else "far"}))
	_tracking = next_tracking
	_clock = tick
	return {"ok": true, "errors": [], "observations": observations.duplicate(true)}

func _visible_distance(observer: Dictionary, target: Dictionary, space: PhysicsDirectSpaceState3D) -> float:
	var excludes: Array[RID] = []
	for rid in observer.exclude_rids:
		excludes.append(rid)
	var forward: Vector3 = observer.forward.normalized()
	var minimum: float = INF
	var cosine: float = cos(deg_to_rad(float(_config.fov_degrees) * 0.5))
	for point in target.sample_points:
		var offset: Vector3 = point - observer.eye
		var distance: float = offset.length()
		if distance < 0.00001 or distance > _config.vision_range:
			continue
		if forward.dot(offset / distance) < cosine:
			continue
		var query = PhysicsRayQueryParameters3D.create(observer.eye, point, int(_config.vision_mask), excludes)
		query.collide_with_bodies = true
		query.collide_with_areas = true
		query.hit_from_inside = true
		var hit: Dictionary = space.intersect_ray(query)
		# Empty rays are not proof that a registered actor was hit.
		if hit.has("rid") and hit.rid in target.collision_rids:
			minimum = minf(minimum, distance)
	return minimum

func _path_distance(origin: Vector3, destination: Vector3, navigation_map: RID) -> float:
	var snap: float = float(_config.navigation_snap_distance)
	if NavigationServer3D.map_get_closest_point(navigation_map, origin).distance_to(origin) > snap or NavigationServer3D.map_get_closest_point(navigation_map, destination).distance_to(destination) > snap:
		return INF
	var path: PackedVector3Array = NavigationServer3D.map_get_path(navigation_map, origin, destination, true, int(_config.navigation_layers))
	if path.size() < 2 or path[0].distance_to(origin) > snap or path[path.size() - 1].distance_to(destination) > snap:
		# Exact coincident anchors have zero path distance, not no path.
		return 0.0 if origin.is_equal_approx(destination) and not path.is_empty() else INF
	var length: float = origin.distance_to(path[0]) + path[path.size() - 1].distance_to(destination)
	for index in range(1, path.size()):
		length += path[index - 1].distance_to(path[index])
	return length

func _observation(tick: int, source: String, content: Dictionary) -> Dictionary:
	_serial += 1
	var delay: int = _rng.randi_range(int(_config.delay_min_ticks), int(_config.delay_max_ticks))
	return {"id": _bot_id + ":sense:" + str(_serial), "bot_id": _bot_id,
		"event_tick": tick, "available_tick": tick + delay, "source": source,
		"speaker_id": "sensor", "content": content.duplicate(true)}

func _valid_config() -> bool:
	if not Data.keys_exact(_config, ["region_ids", "vision_mask", "vision_range", "fov_degrees",
		"near_range", "near_exposure_ticks", "far_exposure_ticks", "refresh_ticks",
		"delay_min_ticks", "delay_max_ticks", "sound_radii", "hearing_near_distance",
		"navigation_layers", "navigation_snap_distance"]):
		return false
	if not _texts(_config.region_ids) or _config.region_ids.is_empty():
		return false
	for key in ["vision_mask", "navigation_layers", "near_exposure_ticks", "far_exposure_ticks",
			"refresh_ticks", "delay_min_ticks", "delay_max_ticks"]:
		if not Data.integer(_config[key]) or _config[key] < 1:
			return false
	if _config.delay_max_ticks < _config.delay_min_ticks or _config.far_exposure_ticks < _config.near_exposure_ticks:
		return false
	for key in ["vision_range", "fov_degrees", "near_range", "hearing_near_distance", "navigation_snap_distance"]:
		if not _number(_config[key]) or _config[key] <= 0.0:
			return false
	if _config.fov_degrees > 360.0 or _config.near_range > _config.vision_range:
		return false
	if not _config.sound_radii is Dictionary or not Data.keys_exact(_config.sound_radii,
			["footstep_run", "footstep_walk", "footstep_crouch", "gunshot", "utility", "defuse"]):
		return false
	for kind in _config.sound_radii:
		if not _number(_config.sound_radii[kind]):
			return false
	return _config.sound_radii.footstep_walk == 0.0 and _config.sound_radii.footstep_crouch == 0.0

func _valid_observer(observer: Dictionary) -> bool:
	if not Data.keys_exact(observer, ["eye", "position", "forward", "exclude_rids", "blind_until_tick", "alive"]):
		return false
	for key in ["eye", "position", "forward"]:
		if not observer[key] is Vector3 or not observer[key].is_finite():
			return false
	if not is_finite(observer.forward.length_squared()) or observer.forward.length_squared() < 0.000001 or not _rids(observer.exclude_rids, true):
		return false
	return Data.integer(observer.blind_until_tick) and observer.alive is bool

func _valid_targets(targets: Array, excludes: Array) -> bool:
	if targets.size() > 64:
		return false
	var ids: Dictionary = {}
	var colliders: Dictionary = {}
	for target in targets:
		if not target is Dictionary or not Data.keys_exact(target, ["enemy_id", "region_id", "sample_points", "collision_rids"]):
			return false
		if not Data.nonempty(target.enemy_id) or ids.has(target.enemy_id) or not Data.nonempty(target.region_id) or target.region_id not in _config.region_ids:
			return false
		if not target.sample_points is Array or target.sample_points.is_empty() or target.sample_points.size() > 3 or not _rids(target.collision_rids, false):
			return false
		for point in target.sample_points:
			if not point is Vector3 or not point.is_finite():
				return false
		for rid in target.collision_rids:
			if rid in excludes or colliders.has(rid):
				return false
			colliders[rid] = true
		ids[target.enemy_id] = true
	return true

func _valid_sounds(sounds: Array, tick: int) -> bool:
	if sounds.size() > 256:
		return false
	var ids: Dictionary = {}
	for event in sounds:
		if not event is Dictionary or not Data.keys_exact(event, ["id", "event_tick", "kind", "position"]):
			return false
		if not Data.nonempty(event.id) or ids.has(event.id) or _sound_records.has(event.id):
			return false
		if not Data.integer(event.event_tick) or event.event_tick != tick or not Data.nonempty(event.kind) or not _config.sound_radii.has(event.kind):
			return false
		if not event.position is Vector3 or not event.position.is_finite():
			return false
		ids[event.id] = true
	return true

func _needs_navigation(observer: Dictionary, sounds: Array) -> bool:
	if observer.alive:
		for event in sounds:
			if _config.sound_radii[event.kind] > 0:
				return true
	return false

func _texts(value: Variant) -> bool:
	if not value is Array:
		return false
	var ids: Dictionary = {}
	for item in value:
		if not Data.nonempty(item) or ids.has(item):
			return false
		ids[item] = true
	return true

func _rids(value: Variant, allow_empty: bool) -> bool:
	if not value is Array or (value.is_empty() and not allow_empty) or value.size() > 16:
		return false
	var ids: Dictionary = {}
	for rid in value:
		if not rid is RID or not rid.is_valid() or ids.has(rid):
			return false
		ids[rid] = true
	return true

func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0.0

func _error(reason: String) -> Dictionary:
	return {"ok": false, "errors": [reason], "observations": []}
