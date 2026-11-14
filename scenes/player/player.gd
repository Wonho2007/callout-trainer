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
@export var stand_height: float = 1.8
@export var crouch_height: float = 1.0

@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D

var _pitch: float = 0.0
var _mouse_captured: bool = false


func _ready() -> void:
	collision_layer = 1 << 1  # layer 2 "player"
	collision_mask = 1 << 0   # collide with layer 1 "world"
	camera.current = true      # activate this camera for the viewport
	_capture_mouse(true)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		camera.rotation.x = _pitch
	if event.is_action_pressed("toggle_mouse"):
		_capture_mouse(not _mouse_captured)


func _physics_process(delta: float) -> void:
	# Translate input into shared-actor intent, then let ActorBase move the body.
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
