extends PanelContainer
# Developer fixture only. Reads copied runtime signals/snapshots and submits
# normalized delayed comms / validated goals. No opponent or sensor handles.
const ACTIONS: Array = [
	["1 Report room", "report"], ["2 Hold home", "home"], ["3 Cover room", "cover"],
	["4 Swing now", "swing"], ["5 Prepare swing", "prepare"], ["6 Go cue", "cue"],
	["7 Follow player", "follow"], ["8 Prepare flash", "flash"], ["9 Cancel", "cancel"],
	["0 Repeat last comm", "repeat"], ["- Invalid goal / fallback", "fallback"]]
const KEYS: Dictionary = {KEY_1: "report", KEY_2: "home", KEY_3: "cover",
	KEY_4: "swing", KEY_5: "prepare", KEY_6: "cue", KEY_7: "follow", KEY_8: "flash",
	KEY_9: "cancel", KEY_0: "repeat", KEY_MINUS: "fallback"}
var _runtime: Node
var _context: Dictionary = {}
var _record: Dictionary = {}
var _last_comm: Dictionary = {}
var _history: Array = []
var _goal: String = ""
var _generation: int = 0
var _serial: int = 0
var _feedback: String = "Waiting for runtime"
var _status: Label
var _buttons: Dictionary = {}

func _ready() -> void:
	name = "DeveloperActionTests"
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = -800
	offset_right = -12
	offset_top = -300
	offset_bottom = -12
	custom_minimum_size = Vector2(610, 205)
	var column := VBoxContainer.new()
	add_child(column)
	var title := Label.new()
	title.text = "DEVELOPER ACTION TEST — synthetic comms/goals; no voice or model"
	column.add_child(title)
	_status = Label.new()
	_status.custom_minimum_size = Vector2(610, 100)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.max_lines_visible = 6
	_status.clip_text = true
	_status.add_theme_font_size_override("font_size", 14)
	column.add_child(_status)
	var grid := GridContainer.new()
	grid.columns = 4
	column.add_child(grid)
	for item in ACTIONS:
		var button := Button.new()
		button.text = item[0]
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(activate.bind(item[1]))
		grid.add_child(button)
		_buttons[item[1]] = button
	var hint := Label.new()
	hint.text = "Esc: mouse/buttons • F: reset • F6/F7: enemy • WASD: move\n5 → wait for READY → 6. 7 → wait for READY → enter hallway in teammate view."
	hint.add_theme_font_size_override("font_size", 13)
	column.add_child(hint)
	_refresh()

func bind_runtime(bot_runtime: Node) -> void:
	_disconnect_runtime()
	_runtime = bot_runtime
	_generation += 1
	_context = {}
	_record = {}
	_last_comm = {}
	_history.clear()
	_goal = ""
	_feedback = "Round bound; waiting for copied context"
	_runtime.policy_context_ready.connect(_on_context)
	_runtime.comm_result.connect(_on_result)
	_runtime.decision_recorded.connect(_on_decision)
	_refresh()

func _exit_tree() -> void:
	_disconnect_runtime()

func _disconnect_runtime() -> void:
	if not is_instance_valid(_runtime):
		return
	for pair in [["policy_context_ready", _on_context], ["comm_result", _on_result], ["decision_recorded", _on_decision]]:
		if _runtime.is_connected(pair[0], pair[1]):
			_runtime.disconnect(pair[0], pair[1])

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and KEYS.has(event.physical_keycode):
		activate(KEYS[event.physical_keycode])
		get_viewport().set_input_as_handled()

func activate(action: String) -> Dictionary:
	if not is_instance_valid(_runtime) or _runtime.current_tick() < 0:
		return _reply(false, "Runtime not ready")
	if action in ["home", "cover"]:
		_goal = action
		return _submit_goal()
	if action == "fallback":
		_goal = ""
		var rejected: Dictionary = _runtime.submit_intent({})
		return _reply(not rejected.ok, "Injected invalid goal: " + rejected.reason + "; scripted fallback")
	if action == "repeat":
		if _last_comm.is_empty():
			return _reply(false, "No comm in this round to repeat")
		var replay: Dictionary = _runtime.submit_comm(_last_comm.duplicate(true))
		return _reply(replay.ok, "Repeated same ID through delayed inbox", _last_comm.message_id)
	var kind: String = "command"
	var payload: Dictionary = {}
	match action:
		"report":
			kind = "report"
			payload = {"action": "report_enemy", "region_id": "room", "count": 1, "hedge": "sure"}
		"swing", "prepare", "follow":
			var mode: String = "now" if action == "swing" else ("on_cue" if action == "prepare" else "follow_player")
			payload = {"action": "swing_together", "target_id": "entry", "timing": {"mode": mode}}
		"flash":
			payload = {"action": "throw_flash", "target_id": "flash_entry", "timing": {"mode": "on_cue"}}
		"cue", "cancel":
			var active: Dictionary = _runtime.snapshot().active_command
			if active.is_empty():
				return _reply(false, "No active command to " + action)
			kind = action
			payload = {"command_id": active.message_id}
		_:
			return _reply(false, "Unknown developer action")
	# Reports/commands stop fixture goal renewal; expired model contexts naturally
	# yield to the fallback. Accepted player commands always take priority.
	_goal = ""
	var issued: int = _runtime.current_tick() + 1
	var message: Dictionary = {"schema_version": "comms.v1", "message_id": _next_id(),
		"speaker_id": "player", "recipient_id": "ally", "issued_tick": issued,
		"expires_tick": issued + (180 if kind in ["cue", "cancel"] else 1200),
		"kind": kind, "payload": payload}
	var queued: Dictionary = _runtime.submit_comm(message)
	if queued.ok:
		_last_comm = message.duplicate(true)
	return _reply(queued.ok, action + " queued (delivery delay applies)", message.message_id)

func _next_id() -> String:
	_serial += 1
	return "dev-action:" + str(_generation) + ":" + str(_serial)

func _submit_goal() -> Dictionary:
	if _context.is_empty() or _runtime.current_tick() >= int(_context.expires_tick):
		return _reply(false, "Waiting for fresh copied context; test goal remains selected")
	var proposal: Dictionary = {"context_id": _context.context_id, "decision_id": _next_id(),
		"bot_id": _context.bot_id, "goal": "hold" if _goal == "home" else "cover",
		"target_id": _goal, "watch_region_id": "entry" if _goal == "home" else "room",
		"evidence_ids": []}
	# Static authored destinations + own reachability require no enemy evidence.
	var result: Dictionary = _runtime.submit_intent(proposal)
	return _reply(result.ok, "Synthetic goal " + _goal + ": " + result.reason)

func _reply(ok: bool, reason: String, id: String = "") -> Dictionary:
	_feedback = reason
	_refresh()
	return {"ok": ok, "reason": reason, "message_id": id}

func _on_context(context: Dictionary) -> void:
	_context = context.duplicate(true)
	if not _goal.is_empty():
		_submit_goal()
	elif _feedback == "Round bound; waiting for copied context":
		_feedback = "Ready for developer action tests"
		_refresh()

func _on_result(result: Dictionary) -> void:
	_history.append(result.duplicate(true))
	while _history.size() > 6:
		_history.pop_front()
	_refresh()

func _on_decision(record: Dictionary) -> void:
	_record = record.duplicate(true)
	_refresh()

func inspect() -> Dictionary:
	return {"context": _context.duplicate(true), "record": _record.duplicate(true),
		"results": _history.duplicate(true), "last_comm": _last_comm.duplicate(true),
		"fixture_goal": _goal, "feedback": _feedback, "generation": _generation}

func _refresh() -> void:
	if not is_instance_valid(_status):
		return
	var physical: Dictionary = _record.get("physical", {})
	var decision: Dictionary = _record.get("plan", {}).get("decision", {})
	var policy: String = _record.get("policy", "waiting")
	if policy == "local_model":
		policy = "synthetic intent fixture"
	var lifecycle: Array = []
	var evidence: Array = decision.get("evidence_ids", [])
	var evidence_text: String = str(evidence.slice(maxi(0, evidence.size() - 2)))
	if evidence.size() > 2:
		evidence_text += " (+%d earlier)" % (evidence.size() - 2)
	for result in _history.slice(maxi(0, _history.size() - 3)):
		lifecycle.append("%s:%s/%s" % [result.message_id.get_slice(":", 2), result.status, result.reason_code])
	_status.text = "Policy: %s | goal: %s → %s\nWhy: %s | evidence: %s\nPhysical: %s / %s | renewed test goal: %s\n%s\n%s" % [
		policy, decision.get("goal", "waiting"), decision.get("target_id", ""),
		decision.get("reason", ""), evidence_text,
		physical.get("state", "waiting"), physical.get("reason", ""),
		_goal if not _goal.is_empty() else "none", _feedback, " → ".join(lifecycle)]
