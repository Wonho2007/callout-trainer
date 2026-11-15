extends Node
var checks: int = 0
var failed: bool = false
var contexts: Array = []

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)

func wait_tick(runtime: Node, tick: int) -> void:
	while runtime.current_tick() < tick:
		await get_tree().physics_frame

func send(peer: StreamPeerTCP, packet: Dictionary) -> void:
	expect(peer.put_data((JSON.stringify(packet) + "\n").to_utf8_buffer()) == OK, "TCP client writes proposal")

func run(scene: Node) -> void:
	var bridge: Node = scene.voice_bridge
	var runtime: Node = scene.runtime
	runtime.policy_context_ready.connect(func(context: Dictionary): contexts.append(context))
	var client := StreamPeerTCP.new()
	expect(client.connect_to_host("127.0.0.1", bridge.server.get_local_port()) == OK, "loopback connect")
	for _i in range(8):
		client.poll()
		await get_tree().physics_frame
	expect(bridge.peer != null, "real TCP accepted")
	var session: String = bridge.session
	send(client, {"type": "host_mode", "session": session, "model_goals": false})
	await wait_tick(runtime, runtime.current_tick() + 3)
	expect(scene.voice_mode_status.text.contains("safe scripted planner"), "selected sprint fallback is visible in HUD")
	var packet: Dictionary = {"type": "proposal", "session": session, "id": "voice-1", "result": "report", "transcript": "one in room",
		"proposal": {"kind": "report", "payload": {"action": "report_enemy", "region_id": "room", "count": 1, "hedge": "sure"}}}
	var before: Vector3 = scene.teammate.global_position
	send(client, packet)
	await wait_tick(runtime, runtime.current_tick() + 4)
	expect(bridge.events.size() == 1 and bridge.events[0].result.ok, "real socket proposal enters delayed runtime")
	var issued: int = bridge.events[0].message.issued_tick
	expect(issued <= runtime.current_tick() and issued >= 0, "Godot stamps actual receipt tick")
	expect(runtime.snapshot().observations.is_empty(), "proposal unavailable before reaction delay")
	send(client, packet)
	await wait_tick(runtime, issued + 17)
	expect(bridge.events.size() == 1, "transport retry cannot create a second comm")
	expect(scene.teammate.global_position.distance_to(before) < 0.1, "no physical response before available tick")
	await wait_tick(runtime, issued + 60)
	expect(runtime.snapshot().observations.size() >= 1, "accepted report delivered")
	expect(scene.teammate.global_position.distance_to(before) > 2, "socket report changes actual shared navigation")
	expect(not contexts.is_empty(), "runtime emits copied model context")
	var frame: Dictionary = contexts[-1]
	var candidate: Dictionary = {"context_id": frame.context_id, "decision_id": "voice-model:1", "bot_id": "ally", "goal": "reposition",
		"target_id": "home", "watch_region_id": "entry", "evidence_ids": frame.observations.map(func(o: Dictionary): return o.id)}
	send(client, {"type": "intent", "session": session, "candidate": candidate})
	await wait_tick(runtime, runtime.current_tick() + 4)
	expect(runtime.snapshot().plan.decision.target_id == "home", "socket goal passes real intent gate")
	client.disconnect_from_host()
	await wait_tick(runtime, runtime.current_tick() + 5)
	expect(bridge.peer == null, "host disconnect observed")
	expect(scene.voice_mode_status.text.contains("offline"), "disconnect status is visible")
	expect(runtime.snapshot().plan.decision.reason != "local_model_goal", "disconnect immediately relinquishes model control")
	# A delayed result from an earlier round is not allowed into the new inbox.
	var old_events: int = bridge.events.size()
	scene._restart()
	while scene._restart_pending:
		await get_tree().physics_frame
	await wait_tick(scene.runtime, 3)
	expect(bridge.session != session, "restart creates a new transport epoch")
	bridge._receive(packet)
	expect(bridge.events.size() == old_events and scene.runtime.snapshot().observations.is_empty(), "old-round output cannot create a comm")
	# Test parser limits without teaching policy new information.
	bridge._receive({"type": "proposal", "session": bridge.session, "id": "bad", "result": "report", "proposal": {"kind": "report", "payload": {}}})
	await wait_tick(scene.runtime, 28)
	expect(scene.runtime.snapshot().observations.is_empty(), "invalid raw report cannot enter copied model context")
	print("PERSON2_VOICE_SMOKE_", "FAIL" if failed else "PASS", " checks=", checks)
	get_tree().quit(1 if failed else 0)
