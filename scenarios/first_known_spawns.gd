extends RefCounted
# Privileged authoring schedule, never a bot policy/model input.
var _schedule: Array = []
var _emitted: Dictionary = {}
var _clock: int = -1

func _init(schedule: Array) -> void:
	_schedule = schedule.duplicate(true)

func due(tick: int) -> Array:
	if tick < _clock:
		return []
	_clock = tick
	var result: Array = []
	for item in _schedule:
		if item.first_known_tick <= tick and not _emitted.has(item.actor_id):
			_emitted[item.actor_id] = true
			result.append(item.duplicate(true))
	return result
