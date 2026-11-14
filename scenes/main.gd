extends Node3D
## Bootstrap scene (Person 1).
##
## Builds the synthetic test room from data, spawns the first-person player at
## the player spawn marker, and handles restart. This is the stage-1 "empty
## synthetic room" entry point; actors beyond the player and all gameplay are
## later increments.

const PlayerScene := preload("res://scenes/player/player.tscn")

@onready var builder = $SandboxBuilder

var _player: CharacterBody3D


func _ready() -> void:
	# The builder builds itself on _ready; ensure it is ready before spawning.
	await get_tree().process_frame
	_spawn_player()
	_update_hud()
	# Confirm the navigation bake produced a usable path once it is ready.
	if not builder.navigation_is_ready:
		await builder.navigation_ready
	_verify_navigation()


func _verify_navigation() -> void:
	var from = builder.get_region_center("region_a")
	var to = builder.get_region_center("region_b")
	if from == null or to == null:
		push_warning("main: could not find region centers for nav check")
		return
	var path: PackedVector3Array = builder.query_path(from as Vector3, to as Vector3)
	if path.size() < 2:
		push_warning("main: navigation path region_a -> region_b is empty; navmesh may not have baked")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart()


func _spawn_player() -> void:
	var spawn: Marker3D = builder.get_spawn("player")
	_player = PlayerScene.instantiate()
	add_child(_player)
	if spawn:
		_player.teleport_to(spawn)
	else:
		push_warning("main: no player spawn marker found; placing at origin")
		_player.global_position = Vector3(0, 1, 0)


func _restart() -> void:
	# Rebuild the room cleanly (no duplicated nodes) and reset the player.
	builder.build_from_file(builder.map_path)
	var spawn: Marker3D = builder.get_spawn("player")
	if _player and spawn:
		_player.teleport_to(spawn)


func _update_hud() -> void:
	var hud := get_node_or_null("HUD/Hints")
	if hud:
		hud.text = "WASD move | Shift walk | Ctrl crouch | Space jump | R restart | Esc free/recapture mouse"
