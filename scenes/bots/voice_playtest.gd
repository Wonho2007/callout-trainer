extends "res://scenes/bots/first_person.gd"
const VoiceBridge = preload("res://scenes/bots/voice_bridge.gd")
var voice_bridge: Node
var voice_mode_status: Label

func _ready() -> void:
	await super._ready()
	# V belongs to push-to-talk in voice scenes. Keep speaking from also
	# triggering the inherited sandbox dash binding.
	for event in InputMap.action_get_events("dash"):
		if event is InputEventKey and event.physical_keycode == KEY_V:
			InputMap.action_erase_event("dash", event)
	var dash_key := InputEventKey.new()
	dash_key.physical_keycode = KEY_B
	InputMap.action_add_event("dash", dash_key)
	$HUD/Hints.text = $HUD/Hints.text.replace("V dash", "B dash") + " | V talk"
	voice_mode_status = Label.new()
	voice_mode_status.position = Vector2(12, 236)
	voice_mode_status.text = "Voice: waiting | Goals: safe scripted planner"
	$HUD.add_child(voice_mode_status)
	voice_bridge = VoiceBridge.new()
	add_child(voice_bridge)
	var port: int = 8765
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--voice-port="):
			port = int(arg.get_slice("=", 1))
	if not voice_bridge.configure(self, port):
		push_error("Cannot listen on local voice port")
		get_tree().quit(1)
		return
	teammate_ready.connect(voice_bridge.attach)
	voice_bridge.attach(runtime)
	_comm_status = "Voice host waiting. Hold V once connected."
	print("PERSON2_VOICE_READY port=", voice_bridge.server.get_local_port())
	if OS.get_cmdline_user_args().has("--voice-smoke"):
		var smoke = load("res://tests/person2/voice_bridge_smoke.gd").new()
		add_child(smoke)
		_smoke_silence_player_input()
		smoke.run(self)
	if OS.get_cmdline_user_args().has("--voice-model-fixture") or OS.get_cmdline_user_args().has("--voice-interpret-fixture"):
		_model_fixture()

func _model_fixture() -> void:
	var initial: Vector3 = teammate.global_position
	var record: Dictionary = {"delivered": false, "model": false, "evidence": false}
	runtime.observation_delivered.connect(func(observation: Dictionary, tick: int):
		if observation.source == "told":
			record.delivered = tick >= observation.available_tick and observation.available_tick >= observation.event_tick + 18)
	runtime.decision_recorded.connect(func(decision: Dictionary):
		if decision.policy == "local_model":
			record.model = true
			for observation in decision.model_record.context.observations:
				if observation.source == "told" and observation.id in decision.model_record.intent.evidence_ids:
					record.evidence = true)
	await get_tree().create_timer(18.0).timeout
	var moved: bool = teammate.global_position.distance_to(initial) > 2.0
	var model_required: bool = OS.get_cmdline_user_args().has("--voice-model-fixture")
	var passed: bool = record.delivered and moved and (not model_required or (record.model and record.evidence))
	print("PERSON2_VOICE_MODEL_" if model_required else "PERSON2_VOICE_INTERPRET_", "PASS" if passed else "FAIL", " ", JSON.stringify(record), " moved=", moved)
	get_tree().quit(0 if passed else 1)

func _restart() -> void:
	await super._restart()
	if is_instance_valid(voice_bridge):
		_comm_status = "Voice connected. Hold V to speak." if voice_bridge.peer != null else "Voice host waiting. Hold V once connected."
