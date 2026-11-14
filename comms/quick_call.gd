extends RefCounted
# Mandatory deterministic quick-call fallback (brief 6.6). This is the menu/alias
# path, not the stretch speech/LLM interpreter. It only proposes intent, target and
# timing from a fixed scenario vocabulary; a trusted caller assigns message IDs,
# actor IDs, issued/expires ticks (COMMANDS.md). It never invents regions, markers
# or coordinates, and never grants access to hidden enemies.
const Values = preload("res://belief/plain_values.gd")
const Reports = preload("res://comms/report_adapter.gd")

const HEDGES: Array = ["sure", "think", "unsure"]
const COMMAND_TIMINGS: Dictionary = {
	"swing_together": ["now", "on_cue", "follow_player"],
	"throw_flash": ["now", "on_cue"],
}

var _speaker_id: String
var _regions: Array
var _entries: Array
var _flashes: Array

# Vocabulary comes from the shared region registry (Person 1) and authored entry/
# flash markers (COMMANDS.md). All lists are copied; the model holds no world nodes.
func _init(speaker_id: String, region_ids: Array, entry_marker_ids: Array = [],
		flash_marker_ids: Array = []) -> void:
	assert(Values.text(speaker_id))
	assert(Values.valid(region_ids) and _unique_texts(region_ids) and not region_ids.is_empty())
	assert(Values.valid(entry_marker_ids) and _unique_texts(entry_marker_ids))
	assert(Values.valid(flash_marker_ids) and _unique_texts(flash_marker_ids))
	_speaker_id = speaker_id
	_regions = region_ids.duplicate()
	_entries = entry_marker_ids.duplicate()
	_flashes = flash_marker_ids.duplicate()

static func _unique_texts(value: Array) -> bool:
	for item in value:
		if not Values.text(item) or value.count(item) != 1:
			return false
	return true

# Menu structure for a Control to render. Pure data; no engine objects. A caller
# with no entry/flash markers simply gets an empty command option list.
func menu() -> Dictionary:
	return {
		"report": {"regions": _regions.duplicate(), "hedges": HEDGES.duplicate(), "counts": [null, 1, 2]},
		"command": {
			"swing_together": {"targets": _entries.duplicate(), "timings": COMMAND_TIMINGS.swing_together.duplicate()},
			"throw_flash": {"targets": _flashes.duplicate(), "timings": COMMAND_TIMINGS.throw_flash.duplicate()},
		},
	}

# Build a validated comms.v1 enemy report from one menu selection. Returns {} when
# the region is outside the known vocabulary, so an unresolved pick can never emit
# an executable message (COMMANDS.md: ask, do not guess).
func report(message_id: String, recipient_id: String, issued_tick: int,
		expires_tick: int, region_id: String, count: Variant = null,
		hedge: String = "sure") -> Dictionary:
	if region_id not in _regions or hedge not in HEDGES:
		return {}
	return Reports.make_report(message_id, _speaker_id, recipient_id,
		issued_tick, expires_tick, region_id, count, hedge)

# Build a validated comms.v1 command. swing_together uses an authored entry marker;
# throw_flash uses an authored flash marker. Unknown targets/timings yield {}.
func command(message_id: String, recipient_id: String, issued_tick: int,
		expires_tick: int, action: String, target_id: String,
		timing_mode: String) -> Dictionary:
	if action not in COMMAND_TIMINGS or timing_mode not in COMMAND_TIMINGS[action]:
		return {}
	var catalog: Array = _entries if action == "swing_together" else _flashes
	if target_id not in catalog:
		return {}
	var message: Dictionary = {
		"schema_version": "comms.v1", "message_id": message_id,
		"speaker_id": _speaker_id, "recipient_id": recipient_id,
		"issued_tick": issued_tick, "expires_tick": expires_tick, "kind": "command",
		"payload": {"action": action, "target_id": target_id, "timing": {"mode": timing_mode}}}
	return message if _valid_command(message) else {}

# Build a cue or cancel referencing an already-issued command. The reference must
# name a command_id; validation of speaker/recipient/active state is Person 2's job.
# Named make_reference (not reference) to avoid the RefCounted.reference() builtin.
func make_reference(message_id: String, recipient_id: String, issued_tick: int,
		expires_tick: int, kind: String, command_id: String) -> Dictionary:
	if kind not in ["cue", "cancel"] or not Values.text(command_id):
		return {}
	var message: Dictionary = {
		"schema_version": "comms.v1", "message_id": message_id,
		"speaker_id": _speaker_id, "recipient_id": recipient_id,
		"issued_tick": issued_tick, "expires_tick": expires_tick, "kind": kind,
		"payload": {"command_id": command_id}}
	return message if _valid_reference(message) else {}

func _valid_envelope(message: Dictionary) -> bool:
	if not Values.valid(message) or not Values.keys(message,
			["schema_version", "message_id", "speaker_id", "recipient_id",
			"issued_tick", "expires_tick", "kind", "payload"]):
		return false
	if message.schema_version != "comms.v1":
		return false
	for key in ["message_id", "speaker_id", "recipient_id"]:
		if not Values.text(message[key]):
			return false
	if message.speaker_id != _speaker_id:
		return false
	return Values.integer(message.issued_tick) and Values.integer(message.expires_tick) and message.expires_tick > message.issued_tick and message.payload is Dictionary

func _valid_command(message: Dictionary) -> bool:
	if not _valid_envelope(message) or message.kind != "command":
		return false
	var payload: Dictionary = message.payload
	if not Values.keys(payload, ["action", "target_id", "timing"]):
		return false
	if payload.action not in COMMAND_TIMINGS or not Values.text(payload.target_id):
		return false
	if not payload.timing is Dictionary or not Values.keys(payload.timing, ["mode"]):
		return false
	return payload.timing.mode in COMMAND_TIMINGS[payload.action]

func _valid_reference(message: Dictionary) -> bool:
	if not _valid_envelope(message) or message.kind not in ["cue", "cancel"]:
		return false
	return Values.keys(message.payload, ["command_id"]) and Values.text(message.payload.command_id)

# Map an executor lifecycle result (Person 2's result object) to a short contextual
# acknowledgment (COMMANDS.md). Returns "" when nothing should be said; the caller
# must not say "Ready" before the executor reports ready. The silent arm records
# status without rendering speech but uses this same mapping for essential status.
static func acknowledgment(status: String, reason_code: String = "") -> String:
	match status:
		"accepted":
			return "Copy"
		"ready":
			return "Ready"
		"executing":
			return "Flashing"
		"completed":
			return ""
		"cancelled":
			return "Standing down"
		"expired":
			return "Too late"
		"failed":
			return "Can't"
		"rejected":
			match reason_code:
				"no_utility":
					return "No flash left"
				"not_ready":
					return "Not ready"
				"busy_committed":
					return "Already committed"
				"ambiguous_target", "unknown_target":
					return "Which one?"
				_:
					return "Can't"
	return ""
