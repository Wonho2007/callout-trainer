extends RefCounted
# Privileged own-weapon adapter. No target Nodes, world lookup or movement API.
# The sole motion controller consumes halt_movement; fire results stay private.
const Data = preload("res://perception/plain_data.gd")
var _bot_id: String
var _actor: Node3D
var _weapon: Node3D
var _target: String = ""
var _acquired_tick: int = -1
var _reloading: bool = false
var _clock: int = -1

func _init(bot_id: String, actor: Node3D, weapon: Node3D) -> void:
	_bot_id = bot_id
	_actor = actor
	_weapon = weapon
	_weapon.reload_started.connect(_on_reload_started)
	_weapon.reload_finished.connect(_on_reload_finished)

func dispose() -> void:
	if is_instance_valid(_weapon):
		if _weapon.reload_started.is_connected(_on_reload_started):
			_weapon.reload_started.disconnect(_on_reload_started)
		if _weapon.reload_finished.is_connected(_on_reload_finished):
			_weapon.reload_finished.disconnect(_on_reload_finished)

func _on_reload_started() -> void:
	_reloading = true

func _on_reload_finished() -> void:
	_reloading = false

func step(tick: int, decision: Dictionary) -> Dictionary:
	if tick < 0 or tick <= _clock:
		return {"ok": false, "halt_movement": true, "reason": "non_monotonic_combat_tick"}
	_clock = tick
	if not Data.valid(decision) or not Data.keys_exact(decision, ["tick", "bot_id", "action", "reason", "enemy_id", "aim_position", "expires_tick", "evidence_ids"]):
		return {"ok": false, "halt_movement": true, "reason": "invalid_combat_decision"}
	if not Data.equal(decision.bot_id, _bot_id) or not Data.equal(decision.tick, tick) or not Data.integer(decision.expires_tick) or not decision.evidence_ids is Array:
		return {"ok": false, "halt_movement": true, "reason": "invalid_combat_decision"}
	if not decision.action is String or not decision.reason is String:
		return {"ok": false, "halt_movement": true, "reason": "invalid_combat_decision"}
	if not is_instance_valid(_actor) or not is_instance_valid(_weapon) or not _actor.is_alive:
		return _status(false, "actor_or_weapon_unavailable")
	if decision.action == "idle":
		_target = ""
		return _status(false, decision.reason)
	if decision.action != "engage" or tick >= decision.expires_tick or not Data.nonempty(decision.enemy_id) or decision.evidence_ids.is_empty() or not _point(decision.aim_position):
		return {"ok": false, "halt_movement": true, "reason": "invalid_or_expired_contact"}
	if _target != decision.enemy_id:
		_target = decision.enemy_id
		_acquired_tick = tick
	var p: Array = decision.aim_position
	var direction: Vector3 = Vector3(p[0], p[1], p[2]) - (_actor.global_position + Vector3.UP * 1.6)
	if not direction.is_finite() or direction.length() < 0.01:
		return _status(true, "invalid_aim_geometry")
	direction = direction.normalized()
	var desired_yaw: float = atan2(-direction.x, -direction.z)
	var error: float = angle_difference(_actor.rotation.y, desired_yaw)
	# Placeholder 360 degrees/s turn and 3 degree firing alignment, independent
	# of frame rate. Aim error settles from 2 to 0.6 degrees over 24 ticks.
	_actor.rotation.y += clampf(error, -TAU / Engine.physics_ticks_per_second, TAU / Engine.physics_ticks_per_second)
	if _reloading:
		return _status(true, "reloading")
	if _weapon.in_mag == 0:
		if _weapon.reserve > 0:
			_weapon.reload()
		return _status(true, "reloading" if _reloading else "out_of_ammo")
	if Vector2(_actor.velocity.x, _actor.velocity.z).length() > 0.15:
		return _status(true, "stopping_to_shoot")
	if absf(angle_difference(_actor.rotation.y, desired_yaw)) > deg_to_rad(3.0):
		return _status(true, "aiming_last_observed_point")
	if not _weapon.can_fire():
		return _status(true, "rifle_cooldown")
	var settle: float = clampf(float(tick - _acquired_tick) / 24.0, 0.0, 1.0)
	var aim_error: float = deg_to_rad(lerpf(2.0, 0.6, settle))
	direction = direction.rotated(Vector3.UP, sin(float(tick) * 0.71) * aim_error)
	var right: Vector3 = direction.cross(Vector3.UP).normalized()
	if not right.is_zero_approx():
		direction = direction.rotated(right, cos(float(tick) * 0.53) * aim_error)
	var before: int = _weapon.in_mag
	# Shared rifle resolves collision/spread/damage. Never return its collider
	# or hit position to policy; completion is a real shot, not a claimed kill.
	_weapon.fire(_actor.global_position + Vector3.UP * 1.6, direction, false, _actor)
	return _status(true, "rifle_fired" if _weapon.in_mag < before else "rifle_not_fired")

func _status(halt: bool, reason: String) -> Dictionary:
	return {"ok": true, "halt_movement": halt, "reason": reason,
		"in_mag": _weapon.in_mag if is_instance_valid(_weapon) else 0,
		"reserve": _weapon.reserve if is_instance_valid(_weapon) else 0,
		"reloading": _reloading}

func _point(value: Variant) -> bool:
	return value is Array and value.size() == 3 and value.all(func(n: Variant) -> bool: return (n is int or n is float) and is_finite(float(n)))
