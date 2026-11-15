extends "res://scenes/bots/first_person.gd"
# Developer-only inherited FPS harness. The normal first-person scene is intact.
const ActionPanel = preload("res://scenes/bots/action_test_panel.gd")
var action_panel: PanelContainer

func _ready() -> void:
	teammate_ready.connect(_bind_action_runtime)
	await super._ready()
	action_panel = ActionPanel.new()
	$HUD.add_child(action_panel)
	_bind_action_runtime(runtime)
	if OS.get_cmdline_user_args().has("--action-smoke"):
		_smoke_silence_player_input()
		var check = load("res://tests/person2/action_playtest_smoke.gd").new()
		add_child(check)
		check.run(self)
	print("PERSON2_ACTION_PLAYTEST_READY synthetic_inputs=true voice_model=false")

func _bind_action_runtime(bot_runtime: Node) -> void:
	bot_runtime.enable_combat(utility)
	# Developer camera setup only: the shared spawn faces a nearby wall.
	# Turn the own player toward the corridor/teammate using its static spawn
	# orientation. Keep the same shared camera, movement and spawn position.
	var player_spawn: Marker3D = builder.get_spawn("player")
	if player_spawn != null and is_instance_valid(_player):
		_player.rotation.y = player_spawn.rotation.y + PI
	if is_instance_valid(action_panel):
		action_panel.bind_runtime(bot_runtime)
