extends ActorBase
## First-person player controller (Person 1).
##
## Builds on the shared ActorBase movement: reads keyboard/mouse input and
## translates it into the same move_dir/move_mode/jump intent that bots use, so
## the player and bots share one movement implementation. Mouse look, crouch
## height and mouse capture are player-only concerns handled here.
##
## Weapons/shooting/damage sources and defuse are later increments.

@export var mouse_sensitivity: float = 0.0025
@export var stand_height: float = 1.96
@export var crouch_height: float = 1.0

@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var weapon: Weapon = $Camera3D/Weapon

## Injected by main: the shared utility system and the HUD overlays.
var utility: UtilitySystem
var flash_overlay: ColorRect
var blind_overlay: ColorRect
var smoke_overlay: ColorRect
## Enemy actors the scan orb tests against (set by main; read-only use).
var scan_targets: Array = []
## When true, movement intent is held at zero (e.g. while defusing). Mouse-look
## and the input/comms channel stay active — only locomotion is rooted.
var movement_locked: bool = false

var _pitch: float = 0.0
var _mouse_captured: bool = false
var _flash_blind_remaining: float = 0.0
var _wave_blind_remaining: float = 0.0
var _applied_waves: Dictionary = {}


func _ready() -> void:
	collision_layer = 1 << 1  # layer 2 "player"
	collision_mask = 1 << 0   # collide with layer 1 "world"
	camera.current = true      # activate this camera for the viewport
	_capture_mouse(true)
	super._ready()             # connect Health.died -> is_alive handling


func _unhandled_input(event: InputEvent) -> void:
	# Mouse look and the mouse/comms channel stay available after death so the
	# player can still observe and (later) send callouts (COMMUNICATION_COACHING).
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		camera.rotation.x = _pitch
	if event.is_action_pressed("toggle_mouse"):
		_capture_mouse(not _mouse_captured)
	# Dash (V): in the current move-input direction, else straight ahead.
	if event.is_action_pressed("dash") and is_alive and _mouse_captured:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var world_dir := transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		dash(world_dir)
	# Reload (F). Only when alive and mouse captured (not in a menu).
	if event.is_action_pressed("reload") and is_alive and _mouse_captured:
		weapon.reload()
	# Throw utility: land it where the player is aiming (first geometry hit).
	if is_alive and _mouse_captured and utility:
		if event.is_action_pressed("throw_smoke"):
			utility.throw_smoke(_aim_landing_point())
		elif event.is_action_pressed("throw_flash"):
			var from := camera.global_position - camera.global_transform.basis.z * 0.4
			var toss := _calc_flash_toss(from)
			var f := utility.throw_flash(from, toss)
			if f:
				f.detonated.connect(_on_flash_detonated)
		elif event.is_action_pressed("throw_molly"):
			var from := camera.global_position - camera.global_transform.basis.z * 0.5
			var toss := -camera.global_transform.basis.z * 10.0 + Vector3.UP * 3.5
			utility.throw_molly(from, toss)
		elif event.is_action_pressed("blind_wave"):
			var from := camera.global_position - camera.global_transform.basis.z * 0.5
			var dir := -camera.global_transform.basis.z
			var w := utility.throw_blind_wave(from, dir)
			if w:
				w.detonated.connect(_on_wave_detonated)
		elif event.is_action_pressed("scan_orb"):
			var from := camera.global_position - camera.global_transform.basis.z * 0.5
			var toss := -camera.global_transform.basis.z * 12.0 + Vector3.UP * 3.0
			utility.throw_scan_orb(from, toss, scan_targets)


## Where the player is aiming lands on the first world surface, else a point
## ahead. Used as the utility deploy position.
func _aim_landing_point() -> Vector3:
	var origin := camera.global_position
	var dir := -camera.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * 40.0)
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit:
		return hit.position
	return origin + dir * 15.0


## Calculate flash toss velocity targeting the player's crosshair aim point.
## Arrives at target in ~0.75s right as fuse expires, popping right in front of target.
func _calc_flash_toss(from: Vector3) -> Vector3:
	var look_dir := -camera.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position + look_dir * 35.0)
	query.collision_mask = 1 << 0 | 1 << 2 | 1 << 6  # world, actors, hitboxes
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	var target_pt: Vector3
	if hit:
		var normal: Vector3 = hit.get("normal", Vector3.UP)
		var dist_to_hit := (hit.position as Vector3 - camera.global_position).length()
		var offset_dist := clampf(dist_to_hit * 0.12, 0.5, 1.2)
		target_pt = (hit.position as Vector3) + normal * offset_dist
		if (target_pt - from).dot(look_dir) < 0.2:
			target_pt = from + look_dir * maxf(dist_to_hit, 2.0)
	else:
		target_pt = camera.global_position + look_dir * 14.0

	var delta := target_pt - from
	var dist_xz := Vector2(delta.x, delta.z).length()
	dist_xz = clampf(dist_xz, 1.5, 25.0)
	var fuse := 0.75
	var speed_xz := clampf(dist_xz / fuse, 4.0, 22.0)
	var dir_xz := Vector3(delta.x, 0.0, delta.z)
	if dir_xz.length_squared() < 0.001:
		dir_xz = Vector3(look_dir.x, 0.0, look_dir.z)
	dir_xz = dir_xz.normalized()
	var vy := clampf((delta.y + 0.5 * 9.8 * fuse * fuse) / fuse, 1.0, 7.5)
	return dir_xz * speed_xz + Vector3.UP * vy


func _on_flash_detonated(source_position: Vector3) -> void:
	# Apply the blind to the player using the same geometry rule as bots: the
	# flash must be visible (clear LOS, not through smoke) to blind.
	var eye := camera.global_position
	var forward := -camera.global_transform.basis.z
	var has_los := _has_clear_los(eye, source_position)
	# Find the active flash to compute duration.
	for flash in utility.active_flashes():
		var dur: float = flash.blind_duration_for(eye, forward, has_los)
		if dur > _flash_blind_remaining:
			_flash_blind_remaining = dur


func _on_wave_detonated(_source_position: Vector3) -> void:
	_sample_passing_waves()

func _sample_passing_waves() -> void:
	if utility == null:
		return
	var eye := camera.global_position
	var forward := -camera.global_transform.basis.z
	for wave in utility.active_blind_waves():
		if not is_instance_valid(wave) or _applied_waves.has(wave.get_instance_id()):
			continue
		var dur: float = wave.passing_blind_duration_for(eye, forward, _has_clear_los(eye, wave.global_position))
		if dur > 0.0:
			_applied_waves[wave.get_instance_id()] = true
			var total := dur + 1.0  # extra second of blackout
			if total > _wave_blind_remaining:
				_wave_blind_remaining = total


## Clear line of sight between two points: not blocked by world geometry or by
## any active smoke (the shared occlusion rule).
func _has_clear_los(a: Vector3, b: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(a, b)
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit:
		return false
	if utility and utility.segment_blocked_by_smoke(a, b):
		return false
	return true


func _fire_weapon() -> void:
	# Fire from the camera along its forward direction. Spread widens while
	# moving. The weapon raycasts against the world and applies damage itself;
	# shots whose line crosses active smoke are blocked (shared LOS rule).
	weapon.occluder = utility
	var origin := camera.global_position
	var direction := -camera.global_transform.basis.z
	var moving := velocity.length() > 0.5
	weapon.fire(origin, direction, moving, self)


func _process(delta: float) -> void:
	# Fade the white flash overlay (E flash).
	if _flash_blind_remaining > 0.0:
		_flash_blind_remaining = maxf(0.0, _flash_blind_remaining - delta)
	if flash_overlay:
		flash_overlay.color.a = clampf(_flash_blind_remaining, 0.0, 1.0)

	# Fade the black blind overlay (G blind wave).
	if _wave_blind_remaining > 0.0:
		_wave_blind_remaining = maxf(0.0, _wave_blind_remaining - delta)
	if blind_overlay:
		blind_overlay.color.a = clampf(_wave_blind_remaining, 0.0, 1.0)

	# In-smoke camera fog: fade in when the camera is inside a smoke volume.
	if smoke_overlay and utility:
		var inside := utility.point_in_smoke(camera.global_position)
		var target := 0.6 if inside else 0.0
		smoke_overlay.color.a = move_toward(smoke_overlay.color.a, target, delta * 4.0)


func _physics_process(delta: float) -> void:
	# The wave affects a viewer as it passes, not only at its endpoint. The
	# source handles wall/range/facing rules; each wave applies only once.
	_sample_passing_waves()
	# When dead, feed no movement input; ActorBase still applies gravity so the
	# body rests on the floor. Input/comms channel stays alive (handled above).
	if not is_alive:
		set_move_dir(Vector3.ZERO)
		super._physics_process(delta)
		return

	# Translate input into shared-actor intent, then let ActorBase move the body.
	# While movement is locked (e.g. defusing), feed zero move intent but keep
	# mouse-look and the input/comms channel alive.
	if movement_locked:
		set_move_dir(Vector3.ZERO)
		super._physics_process(delta)
		return

	var is_crouching := Input.is_action_pressed("crouch")
	if is_crouching:
		move_mode = MoveMode.CROUCH
	elif Input.is_action_pressed("walk"):
		move_mode = MoveMode.WALK
	else:
		move_mode = MoveMode.RUN
	_apply_height(is_crouching)

	if Input.is_action_just_pressed("jump"):
		request_jump()

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var world_dir := transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	set_move_dir(world_dir)

	# Hold-to-fire; the weapon rate-limits itself. Only when mouse is captured.
	if Input.is_action_pressed("fire") and _mouse_captured:
		_fire_weapon()

	super._physics_process(delta)


func _apply_height(crouching: bool) -> void:
	var target := crouch_height if crouching else stand_height
	var capsule := collision.shape as CapsuleShape3D
	if capsule and not is_equal_approx(capsule.height, target):
		capsule.height = target
		collision.position.y = target * 0.5
		camera.position.y = target - 0.2


func _capture_mouse(capture: bool) -> void:
	_mouse_captured = capture
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
