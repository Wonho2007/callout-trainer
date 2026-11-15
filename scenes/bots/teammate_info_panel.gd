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
	for id in ["Title", "Action", "Vision", "Sight", "Sound", "Comm", "Memory"]:
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

func update_information(state: Dictionary) -> void:
	var tick: int = int(state.get("tick", -1))
	var rate: float = float(Engine.physics_ticks_per_second)
	var decision: Dictionary = state.get("plan", {}).get("decision", {})
	_labels.Action.text = "Action: %s | Flash charges: %d" % [decision.get("goal", "waiting"), state.get("flash_count", 0)]
	var remaining: float = maxf(0.0, (int(state.get("own_perception", {}).get("blind_until_tick", 0)) - maxi(0, tick)) / rate)
	_labels.Vision.text = "Vision: BLINDED — %.1fs remaining" % remaining if remaining > 0 else "Vision: ready"
	_labels.Vision.add_theme_color_override("font_color", Color(1, 0.45, 0.3) if remaining > 0 else Color(0.55, 0.95, 0.75))
	var seen: Dictionary = {}
	var heard: Dictionary = {}
	var told: Dictionary = {}
	var delivered: Array = state.get("observations", [])
	var received_count: int = 0
	for observation in delivered:
		# Defense in depth for any future display caller: never render pending data.
		if int(observation.available_tick) > tick:
			continue
		received_count += 1
		match observation.source:
			"seen":
				if observation.content.get("type") == "enemy_seen" and (seen.is_empty() or observation.event_tick >= seen.event_tick):
					seen = observation
			"heard":
				if heard.is_empty() or observation.event_tick >= heard.event_tick:
					heard = observation
			"told":
				if told.is_empty() or observation.event_tick >= told.event_tick:
					told = observation
	_labels.Sight.text = "Last seen: no enemy sighting received"
	if not seen.is_empty():
		_labels.Sight.text = "Last seen: %s in %s (%.1fs ago)" % [seen.content.enemy_id, seen.content.region_id, (tick - seen.event_tick) / rate]
	_labels.Sound.text = "Last heard: nothing received"
	if not heard.is_empty():
		_labels.Sound.text = "Last heard: %s, %s (%.1fs ago)" % [heard.content.get("sound_kind", "sound").replace("_", " "), heard.content.get("distance_class", "unknown distance"), (tick - heard.event_tick) / rate]
	_labels.Comm.text = "Player comms: none received"
	if not told.is_empty():
		var message: Dictionary = told.content.get("message", {})
		var payload: Dictionary = message.get("payload", {})
		_labels.Comm.text = "Player comms: %s %s" % [payload.get("action", message.get("kind", "message")).replace("_", " "), payload.get("region_id", payload.get("target_id", ""))]
	_labels.Memory.text = "Received updates: %d" % received_count
