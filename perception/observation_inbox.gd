extends RefCounted
const Data = preload("res://perception/plain_data.gd")
var _bot_id: String
var _clock: int = -1
var _pending: Array = []
var _all: Dictionary = {}
var _delivered: Dictionary = {}
var _released_at: Dictionary = {}

func _init(bot_id: String) -> void:
	_bot_id = bot_id

func enqueue(observation: Dictionary) -> Dictionary:
	if not Data.valid(observation) or not Data.keys_exact(observation,
		["id", "bot_id", "event_tick", "available_tick", "source", "speaker_id", "content"]):
		return {"ok": false, "reason": "invalid_observation"}
	if not Data.nonempty(observation.id) or not Data.nonempty(observation.bot_id) or observation.bot_id != _bot_id:
		return {"ok": false, "reason": "invalid_recipient"}
	if not Data.integer(observation.event_tick) or not Data.integer(observation.available_tick) or observation.available_tick < observation.event_tick:
		return {"ok": false, "reason": "invalid_time"}
	if not observation.source is String or observation.source not in ["seen", "heard", "told"] or not Data.nonempty(observation.speaker_id) or not observation.content is Dictionary:
		return {"ok": false, "reason": "invalid_observation"}
	if _all.has(observation.id):
		return {"ok": Data.equal(_all[observation.id], observation), "reason": "duplicate_observation"}
	_all[observation.id] = observation.duplicate(true)
	_pending.append(observation.duplicate(true))
	return {"ok": true, "reason": "ok"}

func release(tick: int) -> Array:
	if tick < _clock:
		return []
	_clock = tick
	_pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.available_tick == b.available_tick:
			if a.event_tick != b.event_tick:
				return a.event_tick < b.event_tick
			return a.id < b.id
		return a.available_tick < b.available_tick)
	var due: Array = []
	var waiting: Array = []
	for observation in _pending:
		if observation.available_tick <= tick:
			_delivered[observation.id] = observation.duplicate(true)
			_released_at[observation.id] = tick
			due.append(observation.duplicate(true))
		else:
			waiting.append(observation)
	_pending = waiting
	return due

func evidence_available(id: String, tick: int) -> bool:
	return tick <= _clock and _delivered.has(id) and _released_at[id] <= tick

func available() -> Array:
	return _delivered.values().duplicate(true)

func current_tick() -> int:
	return _clock
