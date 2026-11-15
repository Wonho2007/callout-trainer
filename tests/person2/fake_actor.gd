extends RefCounted
# Deterministic test-only executor. No game physics or world lookups.
var alive: bool = true
var flash_count: int = 1
var flashes_thrown: int = 0
var reachable: Array = ["entry", "flash"]
var feedback: Array = []

func snapshot() -> Dictionary:
	return {"alive": alive, "flash_count": flash_count, "reachable_target_ids": reachable.duplicate()}

func apply(intents: Array) -> void:
	for intent in intents:
		match intent.op:
			"stage":
				feedback.append({"command_id": intent.command_id, "phase": "staged"})
			"start_swing":
				feedback.append({"command_id": intent.command_id, "phase": "completed"})
			"throw_flash":
				flash_count -= 1
				flashes_thrown += 1
				feedback.append({"command_id": intent.command_id, "phase": "completed"})

func take_feedback() -> Array:
	var result: Array = feedback.duplicate(true)
	feedback.clear()
	return result
