extends Node3D
# Privileged, synthetic manual-test bootstrap. Not the shared game main scene.
const Actor = preload("res://actors/actor_base.gd")
const HealthComponent = preload("res://actors/health.gd")
const Builder = preload("res://world/sandbox_builder.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
const Belief = preload("res://belief/region_belief.gd")
const Motion = preload("res://bots/motion_controller.gd")
var _actor: CharacterBody3D
var _room: Node3D
var _executor: RefCounted
var _planner: RefCounted
var _belief: RefCounted
var _motion: RefCounted
var _label: Label
var _buttons: Array[Button] = []
var _tick: int = -1
var _serial: int = 0
var _ready_to_run: bool = false
var _last_event: String = "Baking navigation..."
var _smoke: bool = false
var _coverage_moved: bool = false
var _swing_started: bool = false
var _cancelled: bool = false
var _dead_stopped: bool = false
var _bad_evidence: bool = false
var _reset_checked: bool = false

func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	_ui()
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29.0
	add_child(camera)
	camera.position = Vector3(0, 28, 17)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	_room = Builder.new()
	_room.build_on_ready = false
	add_child(_room)
	# Explicit isolated-map accommodation for Person 1's recorded mismatch.
	NavigationServer3D.map_set_cell_size(get_world_3d().navigation_map, 0.2)
	NavigationServer3D.map_set_cell_height(get_world_3d().navigation_map, 0.1)
	if _room.build_from_file("res://world/maps/test_room.json") != OK:
		push_error("Visual demo room failed to build")
		get_tree().quit(1)
		return
	await _room.navigation_ready
	await get_tree().physics_frame
	await get_tree().process_frame
	_actor = Actor.new()
	_actor.name = "Teammate"
	_actor.collision_layer = 4
	_actor.collision_mask = 1
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	_actor.add_child(collider)
	var health = HealthComponent.new()
	health.name = "Health"
	_actor.add_child(health)
	add_child(_actor)
	_box(_actor, Vector3(0, 0.9, 0), Vector3(0.6, 1.8, 0.6), Color(0.15, 0.7, 1))
	# Yellow nose rotates with the actor, making the watched angle visible.
	_box(_actor, Vector3(0, 1.4, -0.6), Vector3(0.2, 0.2, 0.9), Color.YELLOW)
	_box(self, Vector3(-5, 0.03, 7), Vector3(1.5, 0.04, 1.5), Color(0.1, 0.8, 0.3))
	_box(self, Vector3(5, 0.03, 7), Vector3(1.5, 0.04, 1.5), Color(0.9, 0.2, 0.7))
	_world_label("HOME / staging", Vector3(-5, 0.15, 8.5))
	_world_label("COVER B", Vector3(5, 0.15, 8.5))
	_world_label("A", Vector3(-6, 1, -6))
	_world_label("B", Vector3(6, 1, 6))
	_reset_round()
	_ready_to_run = true
	for button in _buttons:
		button.disabled = false
	print("PERSON2_VISUAL_READY (synthetic movement demo, not a manual pass)")

func _ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 12)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_label = Label.new()
	_label.custom_minimum_size = Vector2(490, 190)
	_label.add_theme_font_size_override("font_size", 16)
	_label.text = "PERSON 2 / SYNTHETIC MOVEMENT DEMO\nBaking navigation..."
	column.add_child(_label)
	for item in [["1  Report enemy B", "report"], ["2  Swing now", "swing"],
		["3  Prepare swing on cue", "prepare"], ["4  Go cue", "cue"],
		["X  Cancel active command", "cancel"], ["K  Kill teammate", "kill"],
		["R  Reset round", "reset"]]:
		var button := Button.new()
		button.text = item[0]
		button.focus_mode = Control.FOCUS_NONE
		button.disabled = true
		button.pressed.connect(_action.bind(item[1]))
		column.add_child(button)
		_buttons.append(button)
	var note := Label.new()
	note.text = "Blue = teammate; yellow = facing direction\nGreen = home; pink = report-driven cover\nMovement only: no combat, voice, smoke or flash.\nEsc closes the demo."
	column.add_child(note)

func _world_label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.018
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	label.position = at

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	visual.material_override = material
	parent.add_child(visual)
	visual.position = at

func _reset_round() -> void:
	_actor.is_alive = true
	_actor.health.reset()
	_actor.position = Vector3(-5, 0, 7)
	_actor.velocity = Vector3.ZERO
	_actor.set_move_dir(Vector3.ZERO)
	_tick = -1
	_serial = 0
	var regions: Array = ["region_a", "region_b", "region_mid"]
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	_executor = Executor.new("ally", {"entries": ["entry"], "flashes": [], "regions": regions, "speakers": ["player"]}, schema, 600)
	_belief = Belief.new("ally", regions, ["enemy"])
	_planner = Planner.new("ally", {"regions": regions, "markers": [
		{"id": "home", "watch_regions": ["region_a"], "roles": ["hold"], "objectives": ["none"]},
		{"id": "cover", "watch_regions": ["region_b"], "roles": ["hold"], "objectives": ["none"]}],
		"baseline_marker_id": "home", "baseline_watch_region": "region_a", "threat_threshold": 0.55,
		"freshness_ticks": 600, "heartbeat_ticks": 30, "switch_margin": 0.1})
	_motion = Motion.new("ally", _actor, _room, {
		"home": {"position": [-5, 0, 7], "watch_points": {"region_a": [-6, 0, -6]}},
		"cover": {"position": [5, 0, 7], "watch_points": {"region_b": [6, 0, 6]}}},
		{"entry": {"stage_marker_id": "home", "route_marker_ids": ["cover"]}})
	_last_event = "Reset: holding home. Press 1 or click Report enemy B."

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var actions: Dictionary = {KEY_1: "report", KEY_2: "swing", KEY_3: "prepare", KEY_4: "cue",
		KEY_X: "cancel", KEY_K: "kill", KEY_R: "reset"}
	if event.keycode == KEY_ESCAPE:
		get_tree().quit()
	elif actions.has(event.keycode):
		_action(actions[event.keycode])

func _action(action: String) -> void:
	if not _ready_to_run:
		return
	if action == "reset":
		_reset_round()
		return
	if action == "kill":
		_actor.apply_damage(100)
		_last_event = "Teammate killed; expect motion to stop. R resets."
		return
	var kind: String = "command"
	var payload: Dictionary
	match action:
		"report":
			kind = "report"
			payload = {"action": "report_enemy", "region_id": "region_b", "count": 1, "hedge": "sure"}
		"swing", "prepare":
			payload = {"action": "swing_together", "target_id": "entry", "timing": {"mode": "now" if action == "swing" else "on_cue"}}
		"cue", "cancel":
			kind = action
			var command: String = _executor.active_command_id()
			if command.is_empty():
				_last_event = "No active command. Use 2 or 3 first."
				return
			payload = {"command_id": command}
		_:
			return
	_serial += 1
	var id: String = "input:" + str(_serial)
	var issued: int = _tick + 1
	var observation: Dictionary = {"id": "obs:" + id, "bot_id": "ally", "event_tick": issued,
		"available_tick": issued + 18, "source": "told", "speaker_id": "player", "content": {
			"type": "comms", "message": {"schema_version": "comms.v1", "message_id": id,
			"speaker_id": "player", "recipient_id": "ally", "issued_tick": issued, "expires_tick": issued + 600,
			"kind": kind, "payload": payload}}}
	var queued: Dictionary = _executor.enqueue(observation)
	_last_event = action + " queued (18-tick delay)" if queued.ok else "Queue rejected: " + str(queued)

func _physics_process(_delta: float) -> void:
	if not _ready_to_run:
		return
	_tick += 1
	var output: Dictionary = _executor.step(_tick, {"alive": _actor.is_alive, "flash_count": 0,
		"reachable_target_ids": ["entry"]}, _motion.take_feedback())
	for report in output.reports:
		for observation in _executor.inbox.available():
			if observation.id in report.evidence_ids:
				var applied: Dictionary = _belief.apply(observation, _tick)
				if not applied.ok:
					push_error("Visual demo belief update failed")
	for result in output.results:
		_last_event = result.message_id + ": " + result.status + " / " + result.reason_code
		_cancelled = _cancelled or result.status == "cancelled"
	for intent in output.intents:
		_swing_started = _swing_started or intent.op == "start_swing"
	var marker: String = ""
	if _actor.position.distance_to(Vector3(-5, 0, 7)) < 0.3:
		marker = "home"
	elif _actor.position.distance_to(Vector3(5, 0, 7)) < 0.3:
		marker = "cover"
	var plan: Dictionary = _planner.decide(_tick, _belief.snapshot(), {"alive": _actor.is_alive,
		"marker_id": marker, "reachable_marker_ids": ["home", "cover"], "role": "hold", "objective": "none"},
		_executor.inbox, _executor.active_command_snapshot())
	var status: Dictionary = _motion.step(_tick, plan, output, _executor.active_command_snapshot(), _executor.inbox)
	var decision: Dictionary = plan.decision
	for id in decision.get("evidence_ids", []):
		_bad_evidence = _bad_evidence or not _executor.inbox.evidence_available(id, _tick)
	_coverage_moved = _coverage_moved or (_actor.position.x > -3 and decision.get("target_id") == "cover")
	_dead_stopped = _dead_stopped or (not _actor.is_alive and _actor.move_dir.is_zero_approx())
	_label.text = "PERSON 2 / SYNTHETIC MOVEMENT DEMO\nTick: %d   Alive: %s\nGoal: %s -> %s   Watch: %s\nMotion: %s / %s\nEvidence: %s\n%s" % [
		_tick, _actor.is_alive, decision.get("goal", "ERROR"), decision.get("target_id", ""),
		decision.get("watch_region_id", ""), status.state, status.reason,
		str(decision.get("evidence_ids", [])), _last_event]
	if _smoke:
		_smoke_step()

func _smoke_step() -> void:
	# Same action callbacks as buttons/keys. Automated lifecycle test only.
	match _tick:
		5: _action("report")
		100: _action("swing")
		300: _action("prepare")
		325: _action("cancel")
		400: _action("kill")
		410:
			var ok: bool = _coverage_moved and _swing_started and _cancelled and _dead_stopped and not _bad_evidence
			if not ok:
				printerr("Visual smoke failure: coverage=", _coverage_moved, " swing=", _swing_started,
					" cancel=", _cancelled, " dead=", _dead_stopped, " bad_evidence=", _bad_evidence)
				get_tree().quit(1)
				return
			if not _reset_checked:
				_reset_checked = true
				_action("reset")
				_smoke = false
				# Reset must create a live actor, empty evidence and fresh executor.
				if not _actor.is_alive or _tick != -1 or not _executor.inbox.available().is_empty():
					get_tree().quit(1)
					return
			print("PERSON2_VISUAL_SMOKE_PASS (actions, physics, reset; no manual/rendering claim)")
			get_tree().quit()
