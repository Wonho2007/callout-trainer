extends RefCounted
# Non-determinism decision log (Person 3, brief 5.4 / 6). Because the LLM interprets and
# decides non-deterministically, we cannot replay to prove fairness or to grade. So every
# interpret/decide call is logged with: the copied inputs the model was given, the full
# prompt, the raw model output, the parsed result, the source (model/fallback), the tick,
# and the evidence_ids those inputs came from. recording/evidence_audit.gd reads the
# evidence_ids/tick to prove the logged inputs were a subset of what the bot could observe
# by that tick. Truth lives in a separate stream the model never sees.
#
# The Python interpreter host (comms/interpreter.py + recording/decision_log.py) writes the
# authoritative runtime log to user://runs/. This GDScript mirror is for decisions made or
# mirrored inside Godot and to hand evidence_audit.gd a record in the shape it expects.
const Values = preload("res://belief/plain_values.gd")

# Keys that must never appear in a decision's inputs (a truth leak). Mirrors the Python
# FORBIDDEN_INPUT_KEYS so both sides enforce the same fairness boundary.
const FORBIDDEN_INPUT_KEYS: Array = [
	"truth", "ground_truth", "scene", "scene_tree", "enemy_transform", "enemy_transforms",
	"enemy_positions", "spectator", "minimap", "global_truth", "world", "node", "nodes",
]

var _records: Array = []

# Build and store one decision record. Returns {} (and records nothing) if the inputs
# contain a forbidden key or the envelope is malformed, so a leak can never be logged as
# if it were fair. evidence_ids lists the observation ids the inputs were copied from;
# evidence_audit.gd checks each was available (available_tick <= tick) for this bot.
func record(bot_id: String, tick: int, kind: String, inputs: Dictionary,
		prompt: Dictionary, raw_output: Variant, parsed: Variant,
		source: String, evidence_ids: Array) -> Dictionary:
	if not Values.text(bot_id) or not Values.integer(tick) or tick < 0:
		return {}
	if kind not in ["interpret", "decide"]:
		return {}
	if source not in ["model", "deterministic_fallback", "deterministic"]:
		return {}
	if not Values.valid(inputs) or _has_forbidden_key(inputs):
		return {}
	if not _text_array(evidence_ids):
		return {}
	var entry: Dictionary = {
		"record_version": "decision_log.v1",
		"bot_id": bot_id,
		"tick": tick,
		"kind": kind,
		"source": source,
		"inputs": inputs.duplicate(true),
		"prompt": prompt.duplicate(true),
		"raw_output": raw_output,
		"parsed": parsed,
		"evidence_ids": evidence_ids.duplicate(),
	}
	_records.append(entry)
	return entry

# All stored records, as the decisions array evidence_audit.gd.check() expects
# (each has bot_id, tick, evidence_ids plus the logged prompt/output/parsed fields).
func decisions() -> Array:
	return _records.duplicate(true)

# Persist to a JSON-lines file under user://runs/ (gitignored). Caller supplies the path.
func flush_to(path: String) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	for entry in _records:
		file.store_line(JSON.stringify(entry))
	file.close()
	return OK

func _has_forbidden_key(value: Variant) -> bool:
	if value is Dictionary:
		for key in value.keys():
			if key is String and key.to_lower() in FORBIDDEN_INPUT_KEYS:
				return true
			if _has_forbidden_key(value[key]):
				return true
	elif value is Array:
		for item in value:
			if _has_forbidden_key(item):
				return true
	return false

static func _text_array(value: Array) -> bool:
	for item in value:
		if not Values.text(item):
			return false
	return true
