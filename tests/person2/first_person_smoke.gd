extends Node
const Data = preload("res://perception/plain_data.gd")
var checks: int = 0
var failed: bool = false
var contexts: Array = []
var records: Array = []
var results: Array = []
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)
func wait_tick(runtime: Node, target: int) -> void:
	while runtime.current_tick() < target:
		await get_tree().physics_frame
func message(runtime: Node, id: String, kind: String, payload: Dictionary) -> Dictionary:
	var tick: int = runtime.current_tick() + 1
	return {"schema_version": "comms.v1", "message_id": id, "speaker_id": "player", "recipient_id": "ally",
		"issued_tick": tick, "expires_tick": tick + 500, "kind": kind, "payload": payload}
func run(scene: Node3D) -> void:
	var runtime: Node = scene.runtime
	runtime.policy_context_ready.connect(func(frame: Dictionary): contexts.append(frame))
	runtime.decision_recorded.connect(func(record: Dictionary): records.append(record))
	runtime.comm_result.connect(func(result: Dictionary): results.append(result))
	await wait_tick(runtime, 2)
	var player: Node3D = scene.get("_player")
	var builder: Node3D = scene.get("builder")
	expect(builder.map_path == "res://world/maps/b_site.json" and builder.map_data.id == "b_site_box", "launch uses Person 1's current map, not the old test room")
	expect(builder.map_data.bounds.min[2] < -6 and not builder.map_data.get("divots", []).is_empty(), "latest deeper room and divot data are loaded")
	var region_ids: Array = []
	for region in builder.map_data.regions:
		region_ids.append(region.id)
	region_ids.sort()
	expect(region_ids == ["corridor", "entry", "room"], "bot vocabulary matches the new map's actual region IDs")
	expect(get_viewport().get_camera_3d() == player.camera, "active camera belongs to shared first-person player")
	var start: Vector3 = scene.teammate.global_position
	var home: Vector3 = Vector3(-2, 0, 11.5)
	var cover: Vector3 = Vector3(0, 0, 3)
	expect(scene.teammate.is_alive and start.distance_to(home) < 0.3, "real teammate spawns at the new authored corridor position")
	expect(builder.get_spawn("teammate") == null, "owned scenario adds teammate placement without mutating Person 1's map registry")
	expect(builder.query_path(start, cover).size() > 2, "new bot route uses the corridor/hallway navigation path")
	# Exercise shared input/movement code, not a replacement player controller.
	var before: Vector3 = player.global_position
	Input.action_press("move_forward")
	player._physics_process(1.0 / 60.0)
	Input.action_release("move_forward")
	expect(player.global_position.distance_to(before) > 0.01, "shared first-person controller physically moves")
	var report: Dictionary = message(runtime, "report", "report", {"action": "report_enemy", "region_id": "room", "count": 1, "hedge": "sure"})
	expect(runtime.submit_comm(report).ok, "voice host seam accepts normalized comm")
	var issued: int = report.issued_tick
	await wait_tick(runtime, issued + 17)
	expect(scene.teammate.global_position.distance_to(start) < 0.1, "comm cannot move bot before delay")
	await wait_tick(runtime, issued + 55)
	expect(scene.teammate.global_position.distance_to(start) > 2 and scene.teammate.global_position.z < start.z - 1, "room report moves teammate from corridor through the hallway")
	await wait_tick(runtime, issued + 155)
	expect(scene.teammate.global_position.distance_to(cover) < 0.35 and runtime.snapshot().physical.state == "holding", "shared physics reaches the new room coverage marker without getting stuck")
	var bad: Dictionary = message(runtime, "foreign", "report", {"action": "report_enemy", "region_id": "entry", "count": 1, "hedge": "sure"})
	bad.recipient_id = "other"
	runtime.submit_comm(bad)
	runtime.submit_comm(message(runtime, "old_map", "report", {"action": "report_enemy", "region_id": "region_b", "count": 1, "hedge": "sure"}))
	await wait_tick(runtime, issued + 185)
	var old_rejected: bool = false
	for result in results:
		old_rejected = old_rejected or (result.message_id == "old_map" and result.status == "rejected" and result.reason_code == "unknown_target")
	expect(old_rejected, "old test-room region names are rejected by the current-map catalog")
	var clean: bool = not contexts.is_empty()
	for frame in contexts:
		for observation in frame.observations:
			clean = clean and observation.available_tick <= frame.tick and observation.content.message.message_id not in ["foreign", "old_map"]
	expect(clean, "model contexts omit future and rejected raw testimony")
	var frame: Dictionary = contexts[-1]
	var intent: Dictionary = {"context_id": frame.context_id, "decision_id": "model:1", "bot_id": "ally",
		"goal": "reposition", "target_id": "home", "watch_region_id": "entry", "evidence_ids": []}
	expect(runtime.submit_intent(intent).ok, "recorded-context model goal passes intent seam")
	await wait_tick(runtime, runtime.current_tick() + 3)
	expect(runtime.snapshot().plan.decision.target_id == "home" and (home - scene.teammate.global_position).dot(scene.teammate.move_dir) > 0, "validated model intent physically overrides fallback coverage")
	var swing: Dictionary = message(runtime, "swing", "command", {"action": "swing_together", "target_id": "entry", "timing": {"mode": "on_cue"}})
	runtime.submit_comm(swing)
	await wait_tick(runtime, int(swing.issued_tick) + 20)
	expect(runtime.snapshot().plan.decision.goal == "command", "accepted player command overrides autonomous model goal")
	intent.decision_id = "model:bad"
	intent.target_id = "hidden_enemy"
	expect(not runtime.submit_intent(intent).ok, "illegal model target rejected")
	var cancel: Dictionary = message(runtime, "cancel", "cancel", {"command_id": "swing"})
	runtime.submit_comm(cancel)
	await wait_tick(runtime, int(cancel.issued_tick) + 22)
	expect(runtime.snapshot().plan.decision.target_id == "cover", "invalid model output/cancel recover to safe fallback")
	player.apply_damage(100)
	expect(scene.get("_round_state") == "active", "player death leaves surviving teammate/voice round active")
	runtime.submit_comm(message(runtime, "after_death", "report", {"action": "report_enemy", "region_id": "entry", "count": null, "hedge": "think"}))
	await wait_tick(runtime, runtime.current_tick() + 22)
	var delivered: bool = false
	for result in results:
		delivered = delivered or (result.message_id == "after_death" and result.status == "completed")
	expect(delivered, "player can still deliver comms after death")
	# Changed hidden world truth is never supplied to the pure gate/model frame.
	var record_before: Dictionary = contexts[-1].duplicate(true)
	scene.get("_target").position += Vector3(1, 0, 0)
	expect(contexts[-1] == record_before, "actual unseen enemy movement does not mutate recorded prompt context")
	scene.teammate.apply_damage(100)
	expect(scene.get("_round_state") == "player_down", "round ends when player and surviving teammate are both dead")
	# Stop smoke driver surviving scene-local reset. The runtime is recreated.
	var old_context: Dictionary = frame.duplicate(true)
	scene._restart()
	while scene.get("_restart_pending"):
		await get_tree().physics_frame
	expect(scene.runtime != runtime and scene.teammate.is_alive and player.is_alive, "restart creates fresh runtime and revives both actors")
	expect(scene.teammate.global_position.distance_to(home) < 0.3 and builder.map_data.id == "b_site_box", "restart retains new map and corridor teammate spawn")
	intent.context_id = old_context.context_id
	intent.target_id = "home"
	intent.decision_id = "old_round"
	expect(not scene.runtime.submit_intent(intent).ok, "old-round model response cannot control new actor")
	expect(not records.is_empty(), "physical decisions publish plain records for Person 3 logging")
	expect(Data.valid(records) and Data.valid(contexts), "recorded contexts and decisions contain only copied plain values")
	scene._on_spike_defused()
	expect(scene.teammate.move_dir.is_zero_approx() and not scene.runtime.submit_comm(report).ok, "public round completion freezes movement and rejects new round actions")
	print("PERSON2_FIRST_PERSON_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	get_tree().quit(1 if failed else 0)
