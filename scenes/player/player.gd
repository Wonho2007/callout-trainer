extends CharacterBody3D
## First-person player controller (Person 1, shared actor mechanics).
##
## Stage-1 scope: mouse look, walk (quiet)/run/crouch/jump movement on the
## greybox with matching collision. Weapons, shooting, damage and defuse are
## later increments. Bot actors (Person 2) reuse the shared movement rules,
## not this input-driven script.
##
## All values are placeholders tuned by playtest (brief §6.3), not Valorant
## mechanics.

@export var run_speed: float = 6.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0025
@export var stand_height: float = 1.8
@export var crouch_height: float = 1.0

@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var _pitch: float = 0.0
var _mouse_captured: bool = false


func _ready() -> void:
	collision_layer = 1 << 1  # layer 2 "player"
	collision_mask = 1 << 0   # collide with layer 1 "world"
	camera.current = true     # activate this camera for the viewport
	_capture_mouse(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		camera.rotation.x = _pitch
	if event.is_action_pressed("toggle_mouse"):
		_capture_mouse(not _mouse_captured)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var is_crouching := Input.is_action_pressed("crouch")
	var is_walking := Input.is_action_pressed("walk")
	_apply_height(is_crouching)

	var speed := run_speed
	if is_crouching:
		speed = crouch_speed
	elif is_walking:
		speed = walk_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()


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


## Place the player at a spawn marker (position + yaw).
func teleport_to(marker: Marker3D) -> void:
	global_position = marker.global_position
	rotation.y = marker.rotation.y
	velocity = Vector3.ZERO
