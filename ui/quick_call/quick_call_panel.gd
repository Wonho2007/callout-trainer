extends Control
# Mandatory quick-call Control (brief 6.6). Thin view over comms/quick_call.gd. It
# renders the fixed menu, emits a chosen comms.v1 message and shows contextual
# lifecycle acknowledgments. It owns no belief/executor state and never edits the
# main scene; a host scene wires the signals to Person 2's inbox/executor.
const QuickCall = preload("res://comms/quick_call.gd")

# Emitted when the player confirms a selection. The payload is a validated comms.v1
# message dictionary; a trusted host still assigns delivery delay and queues it in
# the addressed bot's inbox. Empty payloads are never emitted.
signal message_selected(message: Dictionary)

var _model: RefCounted
var _recipient_id: String = ""
var _list: ItemList
var _ack_label: Label
var _options: Array = []

# region_ids/entry/flash come from the shared registry and authored markers, not
# from the live world. tick_provider returns the current simulation tick so issued/
# expires ticks stay on the authoritative clock; the UI never invents wall-clock time.
var _tick_provider: Callable = Callable()
var _expiry_ticks: int = 100
var _next_serial: int = 0

func configure(speaker_id: String, recipient_id: String, region_ids: Array,
		entry_marker_ids: Array = [], flash_marker_ids: Array = [],
		tick_provider: Callable = Callable(), expiry_ticks: int = 100) -> void:
	_model = QuickCall.new(speaker_id, region_ids, entry_marker_ids, flash_marker_ids)
	_recipient_id = recipient_id
	_tick_provider = tick_provider
	_expiry_ticks = maxi(1, expiry_ticks)
	_rebuild()

func _ready() -> void:
	if not is_instance_valid(_list):
		_build_nodes()

func _build_nodes() -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	add_child(box)
	var title: Label = Label.new()
	title.text = "Quick-call"
	box.add_child(title)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_activated.connect(_on_item_activated)
	box.add_child(_list)
	_ack_label = Label.new()
	_ack_label.text = ""
	box.add_child(_ack_label)

# Flattens the structured menu into a selectable, fully-specified option list. Each
# entry carries everything needed to build a message, so a single click is one
# deterministic, unambiguous call (no free-form text, no guessed coordinates).
func _rebuild() -> void:
	if not is_instance_valid(_list):
		_build_nodes()
	_list.clear()
	_options.clear()
	if _model == null:
		return
	var menu: Dictionary = _model.menu()
	for region in menu.report.regions:
		for hedge in menu.report.hedges:
			_add_option("Enemy %s (%s)" % [region, hedge],
				{"kind": "report", "region_id": region, "hedge": hedge, "count": null})
	for action in menu.command:
		for target in menu.command[action].targets:
			for timing in menu.command[action].timings:
				_add_option("%s -> %s [%s]" % [action, target, timing],
					{"kind": "command", "action": action, "target_id": target, "timing": timing})

func _add_option(label: String, spec: Dictionary) -> void:
	_list.add_item(label)
	_options.append(spec)

func _on_item_activated(index: int) -> void:
	select(index)

# Public so a headless host/test can drive a selection without input events.
func select(index: int) -> Dictionary:
	if _model == null or index < 0 or index >= _options.size():
		return {}
	var tick: int = _current_tick()
	var spec: Dictionary = _options[index]
	var message_id: String = "qc_%d" % _next_serial
	var message: Dictionary = {}
	if spec.kind == "report":
		message = _model.report(message_id, _recipient_id, tick, tick + _expiry_ticks,
			spec.region_id, spec.count, spec.hedge)
	elif spec.kind == "command":
		message = _model.command(message_id, _recipient_id, tick, tick + _expiry_ticks,
			spec.action, spec.target_id, spec.timing)
	if message.is_empty():
		return {}
	_next_serial += 1
	message_selected.emit(message)
	return message

func _current_tick() -> int:
	if _tick_provider.is_valid():
		var value: Variant = _tick_provider.call()
		if value is int:
			return value
	return 0

# Host feeds executor lifecycle results here; the panel shows the bot's short reply.
func show_result(status: String, reason_code: String = "") -> void:
	if not is_instance_valid(_ack_label):
		return
	_ack_label.text = QuickCall.acknowledgment(status, reason_code)
