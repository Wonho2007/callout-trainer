extends Node
class_name GameEvents
## Game event bus (Person 1 emitter side; schema owned by Person 3).
##
## A PRIVILEGED stream of tick-stamped gameplay events for the recorder and
## Person 3's grader/debrief. It forwards the loose signals the gameplay systems
## already emit (shots, damage, death, utility, defuse, detonation) into one
## structured record each.
##
## FAIRNESS BOUNDARY (AGENTS.md, CONTRACTS.md): this is the privileged gameplay
## stream. Records may carry truth such as world positions. It MUST NOT be wired
## into bot policy or any policy input path — only perception's privileged
## recorder and the grader read it. Person 2's bots decide from their own
## delayed observations, never from this bus.
##
## RECORD SHAPE IS A PROPOSAL, not a frozen schema. Person 3 owns shared schemas
## (docs/CONTRACTS.md); this is a privileged gameplay-event stream
## {id, tick, type, actor, position, payload} and must be frozen together.

## Emitted for every recorded event. Consumers: privileged recorder / grader.
signal event_recorded(record: Dictionary)

## Proposed event type strings (coordinate the final set with Person 3).
const T_SHOT_FIRED := "shot_fired"
const T_DAMAGE := "damage_dealt"
const T_DEATH := "actor_died"
const T_UTILITY := "utility_deployed"
const T_DEFUSE_START := "defuse_started"
const T_DEFUSE_STOP := "defuse_stopped"
const T_DEFUSE_DONE := "spike_defused"
const T_DETONATED := "spike_detonated"

var _seq: int = 0
## In-memory log for this run. Person 3 may persist/format it (owns the schema).
var _log: Array[Dictionary] = []


## Current authoritative tick from the physics clock (integer ticks, per
## CONTRACTS.md). Timestamps can be derived from the configured tick rate.
func _tick() -> int:
	return Engine.get_physics_frames()


## Record one event. `actor_id` is a stable string id (or "" if none), `pos` is
## a world position (may be truth — privileged stream), `payload` is extra data.
func record(type: String, actor_id: String, pos: Vector3, payload: Dictionary = {}) -> void:
	_seq += 1
	var rec := {
		"id": "ev_%d" % _seq,
		"tick": _tick(),
		"type": type,
		"actor": actor_id,
		"position": [pos.x, pos.y, pos.z],
		"payload": payload,
	}
	_log.append(rec)
	event_recorded.emit(rec)


## The full run log so far (privileged; grader/recorder only).
func get_log() -> Array[Dictionary]:
	return _log


## Clear the log (e.g. on round restart).
func clear() -> void:
	_log.clear()
	_seq = 0
