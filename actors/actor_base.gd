extends CharacterBody3D
class_name ActorBase
## Shared actor base (Person 1, shared mechanics).
##
## The movement/physics rules the player and all bots share. Bots (Person 2)
## reuse this as their actor component and drive it through intent: set a desired
## move direction or a path to follow, and the actor resolves gravity, speed and
## collision with move_and_slide(). This is the physical executor side only.
##
## Fairness boundary (AGENTS.md): this base holds NO references to other actors
## and exposes none. Bot policy must decide intent from its own delayed
## observations/beliefs (Person 2/3), not by reading other actors here. Movement
## intent is a direction or a world point, never another actor's live transform.
##
## All speeds/values are placeholders tuned by playtest (brief §6.3).

@export var run_speed: float = 6.0
@export var walk_speed: float = 2.5
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5

enum MoveMode { RUN, WALK, CROUCH }

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

## Desired horizontal move direction in world space (normalized). Zero = stop.
## Bots and the player set this each tick; _physics_process applies it.
var move_dir: Vector3 = Vector3.ZERO
var move_mode: int = MoveMode.RUN
var _want_jump: bool = false

## Optional health component child named "Health", if present.
@onready var health: Health = get_node_or_null("Health")

## Emitted when this actor dies (combatant state only). Carries no hidden
## truth — just that this actor died. Consumers: round logic, and Person 3's
## grader via permitted event forwarding. Does NOT expose a killer.
signal died

## False once dead: a dead actor stops moving as a combatant. Death does not
## free the node and (for the player) does not disable the comms/input channel —
## the player must still be able to report after dying (COMMUNICATION_COACHING).
var is_alive: bool = true


func _ready() -> void:
	if health:
		health.died.connect(_on_health_died)


func _on_health_died() -> void:
	is_alive = false
	move_dir = Vector3.ZERO
	died.emit()


func _physics_process(delta: float) -> void:
	# A dead combatant does not move, but still falls so it rests on the floor.
	if not is_alive:
		_apply_gravity(delta)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	_apply_gravity(delta)
	if _want_jump and is_on_floor():
		velocity.y = jump_velocity
	_want_jump = false

	var speed := _speed_for_mode()
	var dir := move_dir
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


func _speed_for_mode() -> float:
	match move_mode:
		MoveMode.WALK: return walk_speed
		MoveMode.CROUCH: return crouch_speed
		_: return run_speed


## --- intent API (used by the player's input and by Person 2's bot policy) ---

## Set the desired world-space move direction (y ignored). Zero to stop.
func set_move_dir(dir: Vector3) -> void:
	move_dir = dir


## Request a jump on the next physics step (applied only if on the floor).
func request_jump() -> void:
	_want_jump = true


## Move toward a world-space point. Returns the distance remaining. Callers
## (e.g. a bot following a navmesh path) step through path points themselves;
## this only turns a target point into a move direction for this tick.
func move_toward_point(point: Vector3) -> float:
	var to := point - global_position
	to.y = 0.0
	set_move_dir(to)
	return to.length()


## Apply damage via the Health component (if any). The physical executor side;
## weapons and area effects call this. Does nothing if no Health or already dead.
func apply_damage(amount: float) -> void:
	if health:
		health.apply_damage(amount)


## Place the actor at a spawn marker (position + yaw). Resets velocity/health
## and revives the combatant (used on round restart).
func teleport_to(marker: Marker3D) -> void:
	global_position = marker.global_position
	rotation.y = marker.rotation.y
	velocity = Vector3.ZERO
	is_alive = true
	if health:
		health.reset()
