extends RefCounted
# PRIVILEGED adapter. Live actors/effects/physics stay here, never in policy.
const Sensor = preload("res://perception/perception_sensor.gd")
var _actor: CharacterBody3D
var _navigation: Node3D
var _utility: Node3D
var _opponents: Dictionary
var _sensor: RefCounted
var _round_prefix: String
var _clock: int = -1
var _sound_serial: int = 0
var _blind_until: int = 0
var _blasts: Dictionary = {}
var _audio_actors: Array = []
var _last_positions: Dictionary = {}
var _last_steps: Dictionary = {}
var _pending_audio: Array = []
var _connections: Array = []
var _snap_distance: float
var _vision_range: float
var _inside_smoke: bool = false
var _view_smoked_off: bool = false
var _smoke_view_known: bool = true

func _init(bot_id: String, actor: CharacterBody3D, navigation: Node3D,
		utility: Node3D, opponents: Dictionary, settings: Dictionary, seed_value: int,
		round_id: int, player: CharacterBody3D = null) -> void:
	_actor = actor
	_navigation = navigation
	_utility = utility
	_opponents = opponents.duplicate()
	_round_prefix = bot_id + ":round:" + str(round_id) + ":"
	_snap_distance = float(settings.navigation_snap_distance)
	_vision_range = float(settings.vision_range)
	var tuning: Dictionary = settings.duplicate(true)
	# Shared Smoke creates its collider while falling but only blocks when
	# active. Use shared active-smoke geometry instead of hitting its raw body.
	tuning.vision_mask = int(tuning.vision_mask) & ~16
	_sensor = Sensor.new(bot_id, tuning, seed_value)
	for target in _opponents.values():
		_register_audio_actor(target)
	if player != null:
		_register_audio_actor(player)
	if _utility != null:
		_connect(_utility, "deployed", _on_utility)

func _connect(emitter: Object, event: String, callback: Callable) -> void:
	emitter.connect(event, callback)
	_connections.append({"emitter": emitter, "event": event, "callback": callback})

func _register_audio_actor(actor: CharacterBody3D) -> void:
	_audio_actors.append(actor)
	_last_positions[actor.get_instance_id()] = actor.global_position
	# Only a shared actor's own weapon events are subscribed, never the archive
	# or an unrestricted global bus. Hit/collider data is ignored.
	var weapon: Node = actor.get_node_or_null("Camera3D/Weapon")
	if weapon != null:
		_connect(weapon, "fired", _on_shot.bind(actor))

func dispose() -> void:
	for item in _connections:
		if is_instance_valid(item.emitter) and item.emitter.is_connected(item.event, item.callback):
			item.emitter.disconnect(item.event, item.callback)
	_connections.clear()
	_audio_actors.clear()
	_opponents.clear()
	_pending_audio.clear()

func _on_shot(_from: Vector3, _to: Vector3, _hit: bool, shooter: Node3D) -> void:
	if is_instance_valid(shooter):
		_pending_audio.append({"kind": "gunshot", "position": shooter.global_position})

func _on_utility(_ability: String, _thrower: String, position: Vector3) -> void:
	_pending_audio.append({"kind": "utility", "position": position})

func _region(point: Vector3) -> String:
	var found: String = ""
	for region in _navigation.map_data.regions:
		var c: Array = region.center
		var s: Array = region.size
		var center := Vector3(c[0], c[1], c[2])
		var half := Vector3(s[0], s[1], s[2]) * 0.5
		var offset: Vector3 = (point - center).abs()
		if offset.x <= half.x and offset.y <= half.y and offset.z <= half.z:
			# Ambiguous overlapping regions are unknown, not guessed identities.
			if not found.is_empty():
				return ""
			found = region.id
	return found

func _clear_segment(eye: Vector3, destination: Vector3) -> bool:
	if _utility != null and _utility.segment_blocked_by_smoke(eye, destination):
		return false
	var query := PhysicsRayQueryParameters3D.create(eye, destination, 7, [_actor.get_rid()])
	return _actor.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _update_blind(tick: int, eye: Vector3, forward: Vector3) -> void:
	if _utility == null:
		return
	var effects: Array = []
	effects.append_array(_utility.active_flashes())
	var waves: Array = _utility.active_blind_waves()
	effects.append_array(waves)
	for effect in effects:
		if not is_instance_valid(effect) or not effect.is_active or _blasts.has(effect.get_instance_id()):
			continue
		_blasts[effect.get_instance_id()] = true
		var duration: float = effect.blind_duration_for(eye, forward, _clear_segment(eye, effect.global_position))
		# Shared player code gives blind-wave blackout one extra second.
		if duration > 0.0 and effect in waves:
			duration += 1.0
		if duration > 0.0:
			_blind_until = maxi(_blind_until, tick + int(ceil(duration * Engine.physics_ticks_per_second)))

func _sounds(tick: int) -> Array:
	for actor in _audio_actors:
		if not is_instance_valid(actor):
			continue
		var id: int = actor.get_instance_id()
		var prior: Vector3 = _last_positions.get(id, actor.global_position)
		_last_positions[id] = actor.global_position
		var moved: float = Vector2(prior.x - actor.global_position.x, prior.z - actor.global_position.z).length()
		var speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
		# Displacement alone turns fixture/reset teleports into false footsteps.
		if actor.is_alive and actor.is_on_floor() and actor.move_mode == 0 and speed > actor.walk_speed and moved > 0.03 and tick - int(_last_steps.get(id, -18)) >= 18:
			_last_steps[id] = tick
			_pending_audio.append({"kind": "footstep_run", "position": actor.global_position})
	var output: Array = []
	var navigation_map: RID = _actor.get_world_3d().navigation_map
	for event in _pending_audio:
		var anchor: Vector3 = NavigationServer3D.map_get_closest_point(navigation_map, event.position)
		# Map airborne utility to its local walkable surface conservatively.
		# Disconnected/off-map sources are never replaced with Euclidean hearing.
		if Vector2(anchor.x - event.position.x, anchor.z - event.position.z).length() > 0.75 or absf(anchor.y - event.position.y) > 3.0:
			continue
		_sound_serial += 1
		output.append({"id": _round_prefix + "audio:" + str(_sound_serial), "event_tick": tick,
			"kind": event.kind, "position": anchor})
	_pending_audio.clear()
	return output

func _update_own_smoke(tick: int, eye: Vector3, forward: Vector3) -> void:
	_inside_smoke = _utility != null and _utility.point_in_smoke(eye)
	_smoke_view_known = _actor.is_alive and tick >= _blind_until
	_view_smoked_off = false
	if _utility == null or _inside_smoke or not _smoke_view_known:
		return
	# Own forward view only, clipped by the first world wall. Do not use any
	# opponent position/collider or infer smoke on the far side of solid cover.
	var end: Vector3 = eye + forward.normalized() * _vision_range
	var query := PhysicsRayQueryParameters3D.create(eye, end, 1)
	query.hit_from_inside = true
	var hit: Dictionary = _actor.get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		end = hit.position
	_view_smoked_off = _utility.segment_blocked_by_smoke(eye, end)

func sample(tick: int) -> Dictionary:
	if tick <= _clock:
		return {"ok": false, "errors": ["non_monotonic_scene_sample"], "observations": []}
	_clock = tick
	var eye: Vector3 = _actor.global_position + Vector3.UP * 1.6
	var forward: Vector3 = -_actor.global_transform.basis.z
	_update_blind(tick, eye, forward)
	_update_own_smoke(tick, eye, forward)
	var targets: Array = []
	for id in _opponents:
		var target: CharacterBody3D = _opponents[id]
		if not is_instance_valid(target) or not target.is_alive:
			continue
		var region: String = _region(target.global_position + Vector3.UP * 0.9)
		if region.is_empty():
			continue
		var points: Array = []
		for height in [1.6, 0.9, 0.2]:
			var point: Vector3 = target.global_position + Vector3.UP * height
			if _utility == null or not _utility.segment_blocked_by_smoke(eye, point):
				points.append(point)
		if not points.is_empty():
			targets.append({"enemy_id": id, "region_id": region, "sample_points": points, "collision_rids": [target.get_rid()]})
	var anchor: Vector3 = NavigationServer3D.map_get_closest_point(_actor.get_world_3d().navigation_map, _actor.global_position)
	var sounds: Array = _sounds(tick)
	var listener_off_navigation: bool = anchor.distance_to(_actor.global_position) > _snap_distance
	if listener_off_navigation:
		# No arbitrarily distant listener snap and no Euclidean hearing fallback.
		sounds.clear()
	var output: Dictionary = _sensor.sample(tick, {"eye": eye, "position": anchor, "forward": forward,
		"exclude_rids": [_actor.get_rid()], "blind_until_tick": _blind_until, "alive": _actor.is_alive},
		targets, sounds, _actor.get_world_3d().direct_space_state, _actor.get_world_3d().navigation_map)
	if listener_off_navigation:
		output.errors.append("listener_off_navigation_hearing_suppressed")
	for observation in output.observations:
		observation.id = _round_prefix + observation.id
	return output

func own_status() -> Dictionary:
	return {"blind_until_tick": _blind_until, "inside_smoke": _inside_smoke,
		"view_smoked_off": _view_smoked_off, "smoke_view_known": _smoke_view_known}
