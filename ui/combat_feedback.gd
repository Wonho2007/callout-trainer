extends Control
## Presentation only. Physical executors supply confirmed, attributed deaths.
var kills: int = 0
var round_serial: int = -1
var _counted: Dictionary = {}
var _health: Health
var _pulse: Tween
var health_text: Label
var health_bar: ProgressBar
var kill_text: Label
var confirmation: Label
var result_screen: ColorRect
var result_title: Label
var result_reason: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.position = Vector2(-252, -122)
	panel.size = Vector2(240, 82)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.045, 0.06, 0.92)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	health_text = _label(20)
	column.add_child(health_text)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(216, 12)
	health_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.35, 0.9, 0.7)
	health_bar.add_theme_stylebox_override("fill", fill)
	column.add_child(health_bar)
	kill_text = _label(16)
	column.add_child(kill_text)
	confirmation = _label(24)
	confirmation.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	confirmation.position = Vector2(-160, 48)
	confirmation.size = Vector2(320, 40)
	confirmation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirmation.text = "ENEMY ELIMINATED"
	confirmation.add_theme_color_override("font_color", Color(0.55, 1, 0.8))
	confirmation.visible = false
	add_child(confirmation)
	# None of the native controls should intercept gameplay mouse input.
	_ignore_mouse(self)
	begin_round(-1, null)

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.98, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	return label

func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)

func begin_round(serial: int, health: Health) -> void:
	round_serial = serial
	_health = health
	kills = 0
	_counted.clear()
	if _pulse != null:
		_pulse.kill()
	confirmation.visible = false
	confirmation.modulate.a = 1.0
	kill_text.text = "YOUR KILLS  0"
	show_result("active")
	refresh_health()

func _process(_delta: float) -> void:
	# Health.reset() is silent; polling also covers max_hp changes and replacement.
	refresh_health()

func refresh_health() -> void:
	if not is_instance_valid(_health):
		return
	health_bar.max_value = maxf(_health.max_hp, 0.001)
	health_bar.value = _health.hp
	health_text.text = "HEALTH  %.1f / %.1f" % [_health.hp, _health.max_hp]

func confirm_kill(victim_id: int, serial: int) -> void:
	if serial != round_serial or round_serial < 0 or _counted.has(victim_id):
		return
	_counted[victim_id] = true
	kills += 1
	kill_text.text = "YOUR KILLS  %d" % kills
	if _pulse != null:
		_pulse.kill()
	confirmation.modulate.a = 1.0
	confirmation.visible = true
	_pulse = create_tween()
	_pulse.tween_interval(0.55)
	_pulse.tween_property(confirmation, "modulate:a", 0.0, 0.4)
	_pulse.tween_callback(confirmation.hide)

func build_result_screen() -> ColorRect:
	result_screen = ColorRect.new()
	result_screen.name = "VictoryScreen" # Preserve existing scene/test lookup.
	result_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_screen.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	result_title = _label(64)
	result_reason = _label(24)
	var prompt := _label(20)
	prompt.text = "Press F to restart"
	for label in [result_title, result_reason, prompt]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
	_ignore_mouse(result_screen)
	result_screen.visible = false
	return result_screen

func show_result(state: String) -> void:
	if not is_instance_valid(result_screen):
		return
	var reasons := {"enemies_eliminated": "All opponents eliminated", "detonated": "Spike detonated",
		"defused": "Spike defused", "player_down": "Player and teammate eliminated"}
	var shown := reasons.has(state)
	result_screen.visible = shown
	if not shown:
		return
	var won := state in ["enemies_eliminated", "detonated"]
	result_title.text = "VICTORY" if won else "DEFEAT"
	result_title.add_theme_color_override("font_color", Color(0.6, 0.95, 0.75) if won else Color(1, 0.45, 0.4))
	result_screen.color = Color(0.03, 0.06, 0.04, 0.86) if won else Color(0.09, 0.025, 0.03, 0.86)
	result_reason.text = reasons[state]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
