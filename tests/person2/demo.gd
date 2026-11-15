extends SceneTree
const Executor = preload("res://bots/command_executor.gd")
const Actor = preload("res://tests/person2/fake_actor.gd")

func _initialize() -> void:
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	var executor = Executor.new("ally", {"entries": ["entry"], "flashes": ["flash"], "regions": ["logs"], "speakers": ["player"]}, schema)
	var actor = Actor.new()
	var event_count: int = 0
	var swings: int = 0
	var reports: int = 0
	for tick in range(12):
		if tick == 0:
			executor.enqueue(told("request", msg("swing", "command", {"action": "swing_together", "target_id": "entry", "timing": {"mode": "follow_player"}}, 0), 2))
		if tick == 3:
			executor.enqueue(told("report", msg("logs", "report", {"action": "report_enemy", "region_id": "logs", "count": 1, "hedge": "sure"}, 3), 4))
		if tick == 4:
			executor.enqueue({"id": "movement", "bot_id": "ally", "event_tick": 4, "available_tick": 6, "source": "seen", "speaker_id": "player",
				"content": {"type": "player_entry", "actor_id": "player", "entry_id": "entry"}})
		if tick == 8:
			executor.enqueue(told("flash", msg("flash", "command", {"action": "throw_flash", "target_id": "flash", "timing": {"mode": "now"}}, 8), 9))
		var output: Dictionary = executor.step(tick, actor.snapshot(), actor.take_feedback())
		if not output.errors.is_empty():
			printerr(output.errors)
			quit(1)
			return
		for intent in output.intents:
			if intent.op == "start_swing":
				swings += 1
		reports += output.reports.size()
		if not output.results.is_empty() or not output.intents.is_empty() or not output.reports.is_empty():
			print(JSON.stringify({"tick": tick, "output": output}))
			event_count += 1
		actor.apply(output.intents)
	if swings != 1 or reports != 1 or actor.flashes_thrown != 1 or not executor.active_command_id().is_empty():
		printerr("Demo outcome mismatch")
		quit(1)
		return
	print("PERSON2_DEMO_PASS: synthetic trace; events=", event_count, "; swing=1; report=1; flash=1. No 3D physics or speech.")
	quit(0)

func msg(id: String, kind: String, payload: Dictionary, issued: int) -> Dictionary:
	return {"schema_version": "comms.v1", "message_id": id, "speaker_id": "player", "recipient_id": "ally", "issued_tick": issued, "expires_tick": 100, "kind": kind, "payload": payload}

func told(id: String, message: Dictionary, available: int) -> Dictionary:
	return {"id": id, "bot_id": "ally", "event_tick": message.issued_tick, "available_tick": available, "source": "told", "speaker_id": "player",
		"content": {"type": "comms", "message": message}}
