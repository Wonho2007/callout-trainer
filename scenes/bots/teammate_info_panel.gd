extends PanelContainer
# Read-only presentation of copied, delivered bot-local information. No world
# handles or target queries. Test-tool signals go only to privileged scene code.
signal enemy_preset_requested(preset: String)
signal enemy_placement_requested
signal flash_test_requested
var _labels: Dictionary = {}

func _ready() -> void:
	position = Vector2(12, 245)
	custom_minimum_size.x = 400
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.085, 0.94)
	style.border_color = Color(0.25, 0.55, 0.75, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	add_child(column)
	for id in ["Title", "Action", "Vision", "Smoke", "Sight", "Sound", "Comm", "Entry", "Memory"]:
		var label := Label.new()
		label.name = id
		label.add_theme_font_size_override("font_size", 14 if id != "Title" else 18)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
		_labels[id] = label
	_labels.Title.text = "TEAMMATE INFORMATION"
	_labels.Memory.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	column.add_child(HSeparator.new())
	var tools := Label.new()
	tools.text = "PERCEPTION TEST TOOLS"
	tools.add_theme_font_size_override("font_size", 14)
	column.add_child(tools)
	var presets := HBoxContainer.new()
	column.add_child(presets)
	_button(presets, "Enemy to entry [F6]", func(): enemy_preset_requested.emit("entry"))
	_button(presets, "Enemy to room [F7]", func(): enemy_preset_requested.emit("room"))
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_button(actions, "Place at crosshair [P]", func(): enemy_placement_requested.emit())
	_button(actions, "Flash teammate [F8]", func(): flash_test_requested.emit())
	var hint := Label.new()
	hint.text = "Arrow keys move enemy relative to your view.\nEsc releases mouse for buttons. F resets round.\nLast seen is memory; it does not track hidden movement."
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	column.add_child(hint)
	var feedback := Label.new()
	feedback.name = "ToolsFeedback"
	feedback.add_theme_font_size_override("font_size", 12)
	feedback.text = "F6 brings the enemy into the initial teammate's view."
	column.add_child(feedback)
	_labels.ToolsFeedback = feedback
	update_information({})

func _button(parent: Control, caption: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(callback)
	parent.add_child(button)

func text_for(id: String) -> String:
	return _labels[id].text

func set_tool_feedback(message: String) -> void:
	_labels.ToolsFeedback.text = message

func set_test_tools_enabled(enabled: bool) -> void:
	var column: Node = get_child(0)
	for index in range(9, column.get_child_count()):
		var control: Control = column.get_child(index)
		control.visible = enabled

func update_information(state: Dictionary) -> void:
	var tick: int = int(state.get("tick", -1))
	var rate: float = float(Engine.physics_ticks_per_second)
	var decision: Dictionary = state.get("plan", {}).get("decision", {})
	_labels.Action.text = "Action: %s | Flash charges: %d" % [decision.get("goal", "waiting"), state.get("flash_count", 0)]
	var remaining: float = maxf(0.0, (int(state.get("own_perception", {}).get("blind_until_tick", 0)) - maxi(0, tick)) / rate)
	_labels.Vision.text = "Vision: BLINDED — %.1fs remaining" % remaining if remaining > 0 else "Vision: ready"
	_labels.Vision.add_theme_color_override("font_color", Color(1, 0.45, 0.3) if remaining > 0 else Color(0.55, 0.95, 0.75))
	var perception: Dictionary = state.get("own_perception", {})
	var inside: bool = perception.get("inside_smoke", false)
	var smoked_off: bool = perception.get("view_smoked_off", false)
	_labels.Smoke.text = "Smoke: clear on watched angle"
	if inside:
		_labels.Smoke.text = "Smoke: IN SMOKE — sight blocked"
	elif not perception.get("smoke_view_known", true):
		_labels.Smoke.text = "Smoke: forward view unknown while blinded/down"
	elif smoked_off:
		_labels.Smoke.text = "Smoke: SMOKED OFF — watched angle blocked"
	_labels.Smoke.add_theme_color_override("font_color", Color(1, 0.75, 0.35) if inside or smoked_off else Color(0.65, 0.75, 0.85))
	if remaining <= 0 and (inside or smoked_off):
		_labels.Vision.text = "Vision: blocked by smoke" if inside else "Vision: restricted by smoke"
		_labels.Vision.add_theme_color_override("font_color", Color(1, 0.75, 0.35))
	var seen: Dictionary = {}
	var heard: Dictionary = {}
	var told: Dictionary = {}
	var entry_motion: Dictionary = {}
	var delivered: Array = state.get("observations", [])
	var received_count: int = 0
	for observation in delivered:
		# Defense in depth for any future display caller: never render pending data.
		if int(observation.available_tick) > tick:
			continue
		received_count += 1
		match observation.source:
			"seen":
				if observation.content.get("type") in ["enemy_seen", "enemy_seen_unknown_region"] and (seen.is_empty() or observation.event_tick >= seen.event_tick):
					seen = observation
				if observation.content.get("type") == "player_entry" and (entry_motion.is_empty() or observation.event_tick >= entry_motion.event_tick):
					entry_motion = observation
			"heard":
				if heard.is_empty() or observation.event_tick >= heard.event_tick:
					heard = observation
			"told":
				if told.is_empty() or observation.event_tick >= told.event_tick:
					told = observation
	_labels.Sight.text = "Last seen: no enemy sighting received"
	if not seen.is_empty():
		var region: String = seen.content.get("region_id", "unknown region")
		_labels.Sight.text = "Last seen: %s in %s (%.1fs ago)" % [seen.content.enemy_id, region, (tick - seen.event_tick) / rate]
	_labels.Sound.text = "Last heard: nothing received"
	if not heard.is_empty():
		_labels.Sound.text = "Last heard: %s, %s (%.1fs ago)" % [heard.content.get("sound_kind", "sound").replace("_", " "), heard.content.get("distance_class", "unknown distance"), (tick - heard.event_tick) / rate]
	_labels.Comm.text = "Player comms: none received"
	if not told.is_empty():
		var message: Dictionary = told.content.get("message", {})
		var payload: Dictionary = message.get("payload", {})
		_labels.Comm.text = "Player comms: %s %s" % [payload.get("action", message.get("kind", "message")).replace("_", " "), payload.get("region_id", payload.get("target_id", ""))]
	_labels.Memory.text = "Received updates: %d" % received_count
	_labels.Entry.text = "Player entry: no movement seen"
	if not entry_motion.is_empty():
		_labels.Entry.text = "Player entry: %s (%.1fs ago)" % [entry_motion.content.entry_id, (tick - entry_motion.event_tick) / rate]
	# Round completion intentionally stops the runtime clock/sensing. Do not
	# present frozen last-known status as live readiness or a still-active plan.
	var physical: Dictionary = state.get("physical", {})
	if physical.get("reason") == "actor_dead":
		_labels.Action.text = "Action: teammate down"
		_labels.Vision.text = "Vision: inactive — teammate down"
		_labels.Vision.add_theme_color_override("font_color", Color(1, 0.75, 0.35))
		_labels.Smoke.text = "Smoke: no live view — teammate down"
	if physical.get("reason") in ["detonated", "defused", "team_eliminated", "enemies_eliminated"]:
		_labels.Action.text = "Action: round ended — press F to reset"
		_labels.Vision.text = "Vision: inactive — round ended"
		_labels.Vision.add_theme_color_override("font_color", Color(1, 0.75, 0.35))
		_labels.Smoke.text = "Smoke: no live updates — round ended"
