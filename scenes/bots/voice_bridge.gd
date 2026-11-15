extends Node
# Privileged local transport adapter. Only copied runtime context leaves this node.
const Data = preload("res://perception/plain_data.gd")
var server := TCPServer.new()
var peer: StreamPeerTCP
var runtime: Node
var scene: Node
var session: String = ""
var buffer := PackedByteArray()
var seen: Dictionary = {}
var last_contact_ms: int = 0
var serial: int = 0
var events: Array = []
var _outgoing := PackedByteArray()
var _last_decision: String = ""

func _requests_swing_preparation(transcript: String) -> bool:
	# Explicit preparation cannot be upgraded to immediate execution by an
	# interpreter proposal. Target grounding and normal delivery still apply.
	var preparation := RegEx.new()
	preparation.compile("\\b(get\\s+ready|be\\s+ready|ready\\s+up|ready\\s+to\\s+(swing|peek)|prepare\\s+to\\s+(swing|peek)|stand\\s+by|on\\s+my\\s+(cue|call|signal)|wait\\s+for\\s+my\\s+(cue|call|signal)|until\\s+i\\s+(say|call))\\b")
	return preparation.search(transcript.to_lower()) != null

func configure(owner_scene: Node, port: int = 8765) -> bool:
	scene = owner_scene
	return server.listen(port, "127.0.0.1") == OK

func _requests_direct_flash(transcript: String) -> bool:
	var flash := RegEx.new()
	flash.compile("^(please\\s+)?(can\\s+you\\s+)?(flash|throw\\s+(a\\s+)?flash)\\b")
	return flash.search(transcript.strip_edges().to_lower()) != null

func _requested_position(transcript: String) -> String:
	# A narrow imperative guard grounds explicit positioning in the public zone
	# catalog even if the swing/flash-only interpreter asks for clarification.
	var words: String = transcript.to_lower().replace("_", " ").strip_edges()
	var imperative := RegEx.new()
	imperative.compile("^(please\\s+)?(can\\s+you\\s+)?(let's\\s+|lets\\s+)?(play|hold|stay|come|go|move|rotate|group|join|meet|take|watch|push)\\b")
	if imperative.search(words) == null or _requests_direct_flash(words) or _requests_swing_preparation(words):
		return ""
	# Do not steal multi-action utility/swing requests or enemy reports.
	var other := RegEx.new()
	other.compile("\\b(flash|smoke|molly|swing|peek|enemy|enemies)\\b")
	if other.search(words) != null:
		return ""
	var matches: Array = []
	for region in scene._scenario.planner.regions:
		var names: Array = [str(region).replace("_", " ")]
		if str(region).begins_with("b_"):
			names.append(str(region).trim_prefix("b_").replace("_", " "))
		for name in names:
			var location := RegEx.new()
			location.compile("\\b" + name + "\\b")
			if location.search(words) != null:
				matches.append(region)
				break
	return matches[0] if matches.size() == 1 else ""

func attach(bot_runtime: Node) -> void:
	runtime = bot_runtime
	session = str(Time.get_ticks_usec())
	seen.clear()
	_last_decision = ""
	runtime.policy_context_ready.connect(_context)
	runtime.decision_recorded.connect(_decision)
	runtime.comm_result.connect(func(result: Dictionary): _send({"type": "comm_result", "session": session, "result": result}))
	runtime.observation_delivered.connect(func(observation: Dictionary, tick: int):
		_send({"type": "observation", "session": session, "observation": observation, "delivery_tick": tick}))
	if peer != null:
		_hello()

func _hello() -> void:
	var affords: Dictionary = {}
	for marker in scene._scenario.motion_markers:
		affords[marker] = scene._scenario.motion_markers[marker].watch_points.keys()
	_send({"type": "hello", "session": session, "regions": scene._scenario.planner.regions,
		"affordances": affords, "synthetic": true,
		"command_targets": scene._scenario.get("command_targets", {"swing_together": {"entry": "entry"}, "throw_flash": {"entry": "flash_entry"}})})

func _context(context: Dictionary) -> void:
	_send({"type": "context", "session": session, "context": context})

func _decision(record: Dictionary) -> void:
	var decision: Dictionary = record.plan.get("decision", {})
	var signature: String = str([record.policy, decision.get("target_id"), decision.get("goal"), decision.get("evidence_ids"), record.errors])
	if signature != _last_decision:
		_last_decision = signature
		_send({"type": "decision", "session": session, "record": record})

func _process(_delta: float) -> void:
	if peer == null and server.is_connection_available():
		peer = server.take_connection()
		peer.set_no_delay(true)
		last_contact_ms = Time.get_ticks_msec()
		_hello()
		scene._comm_status = "Voice connected. Hold V to speak."
	if peer == null:
		return
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_msec() - last_contact_ms > 4000:
		_disconnect()
		return
	if not _outgoing.is_empty():
		var sent: Array = peer.put_partial_data(_outgoing)
		if sent[0] != OK:
			_disconnect()
			return
		_outgoing = _outgoing.slice(int(sent[1]))
	var count: int = peer.get_available_bytes()
	if count > 0:
		var received: Array = peer.get_data(mini(count, 65536))
		if received[0] != OK:
			_disconnect()
			return
		buffer.append_array(received[1])
	if buffer.size() > 262144:
		_disconnect()
		return
	for _i in range(8):
		var boundary: int = buffer.find(10)
		if boundary < 0:
			break
		var parsed: Variant = JSON.parse_string(buffer.slice(0, boundary).get_string_from_utf8())
		buffer = buffer.slice(boundary + 1)
		if parsed is Dictionary and Data.valid(parsed):
			last_contact_ms = Time.get_ticks_msec()
			_receive(parsed)

func _receive(packet: Dictionary) -> void:
	if not is_instance_valid(runtime) or packet.get("session") != session:
		return
	var kind: String = str(packet.get("type", ""))
	if kind == "ping":
		return
	if kind == "host_mode":
		scene.voice_mode_status.text = "Voice: local LLM | Goals: experimental model" if packet.get("model_goals", false) else "Voice: local LLM | Goals: safe scripted planner"
		return
	if kind == "intent":
		var candidate: Variant = packet.get("candidate")
		var answer: Dictionary = runtime.submit_intent(candidate) if candidate is Dictionary else {"ok": false, "reason": "invalid_candidate"}
		_send({"type": "intent_result", "session": session, "result": answer})
		return
	if kind == "model_failure":
		runtime.invalidate_model_goal()
		scene._comm_status = "Model unavailable. Safe fallback active."
		return
	if kind not in ["proposal", "cue", "cancel"] or not Data.nonempty(packet.get("id")):
		return
	var request_id: String = packet.id
	if seen.has(request_id):
		_send(seen[request_id])
		return
	if seen.size() >= 512:
		_disconnect()
		return
	var position: String = _requested_position(str(packet.get("transcript", ""))) if kind == "proposal" else ""
	var cancel_position: bool = kind == "cancel" and not runtime.snapshot().get("player_goal", {}).is_empty()
	if not position.is_empty() or cancel_position:
		var answer: Dictionary = runtime.submit_position_order(position)
		var reply: Dictionary = {"type": "submitted", "session": session, "id": request_id,
			"position_order": position, "result": answer}
		seen[request_id] = reply.duplicate(true)
		events.append(reply.duplicate(true))
		_send(reply)
		scene._comm_status = "Heard: " + str(packet.get("transcript", kind)) + " (delivery pending)"
		return
	var tick: int = runtime.current_tick() + 1
	var preparation_guard: bool = false
	serial += 1
	var message: Dictionary = {"schema_version": "comms.v1", "message_id": "voice:" + session + ":" + str(serial),
		"speaker_id": "player", "recipient_id": "ally", "issued_tick": tick, "expires_tick": tick + 600}
	if kind in ["cue", "cancel"]:
		var active: Dictionary = runtime.snapshot().active_command
		message["kind"] = kind
		message["payload"] = {"command_id": active.get("message_id", "")}
	else:
		if packet.get("result") not in ["report", "command"]:
			scene._comm_status = str(packet.get("question", packet.get("reason", "Please say that again.")))
			return
		var proposal: Variant = packet.get("proposal")
		if not proposal is Dictionary or not proposal.get("payload") is Dictionary or proposal.get("kind") != packet.result:
			return
		message["kind"] = proposal.kind
		message["payload"] = proposal.payload.duplicate(true)
		if proposal.kind == "command":
			if _requests_direct_flash(str(packet.get("transcript", ""))):
				message.payload["action"] = "throw_flash"
				message.payload["timing"] = {"mode": "on_cue" if _requests_swing_preparation(str(packet.transcript)) else "now"}
			if message.payload.get("action") == "swing_together" and _requests_swing_preparation(str(packet.get("transcript", ""))):
				message.payload["timing"] = {"mode": "on_cue"}
				preparation_guard = true
			var mappings: Dictionary = scene._scenario.get("command_targets", {"swing_together": {"entry": "entry"}, "throw_flash": {"entry": "flash_entry"}})
			var target: Variant = mappings.get(message.payload.get("action"), {}).get(message.payload.get("target_id"))
			if target == null:
				scene._comm_status = "No authored action for that location. Please clarify."
				return
			message.payload.target_id = target
	var accepted: Dictionary = runtime.submit_comm(message)
	var reply: Dictionary = {"type": "submitted", "session": session, "id": request_id, "message": message, "result": accepted}
	if preparation_guard:
		reply["timing_guard"] = "preparation_waits_for_cue"
	seen[request_id] = reply.duplicate(true)
	events.append(reply.duplicate(true))
	_send(reply)
	scene._comm_status = "Heard: " + str(packet.get("transcript", kind)) + " (delivery pending)"

func _send(packet: Dictionary) -> void:
	if peer == null:
		return
	var bytes: PackedByteArray = (JSON.stringify(packet) + "\n").to_utf8_buffer()
	if _outgoing.size() + bytes.size() > 524288:
		_disconnect()
		return
	_outgoing.append_array(bytes)

func _disconnect() -> void:
	if peer != null:
		peer.disconnect_from_host()
	peer = null
	buffer.clear()
	_outgoing.clear()
	if is_instance_valid(runtime):
		runtime.invalidate_model_goal()
	if is_instance_valid(scene):
		scene._comm_status = "Voice disconnected. Safe fallback active."
		if is_instance_valid(scene.voice_mode_status):
			scene.voice_mode_status.text = "Voice: offline | Goals: safe scripted planner"

func _exit_tree() -> void:
	_disconnect()
	server.stop()
