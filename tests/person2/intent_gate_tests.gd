extends SceneTree
const Gate = preload("res://bots/intent_gate.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
var checks: int = 0
var failed: bool = false
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)
func context() -> Dictionary:
	return {"context_id": "c", "bot_id": "ally", "tick": 2, "expires_tick": 5,
		"observations": [{"id": "r", "bot_id": "ally", "available_tick": 2}],
		"belief": {}, "own_state": {"reachable_marker_ids": ["cover"]}, "active_command": {}}
func proposal() -> Dictionary:
	return {"context_id": "c", "decision_id": "d", "bot_id": "ally", "goal": "reposition",
		"target_id": "cover", "watch_region_id": "region_b", "evidence_ids": ["r"]}
func _initialize() -> void:
	var gate = Gate.new("ally", {"cover": ["region_b"]})
	var frame: Dictionary = context()
	expect(gate.remember(frame), "remember copied allowed context")
	frame.observations.clear()
	expect(gate.propose(proposal(), 2).ok, "caller mutation cannot remove captured evidence")
	var inbox = Inbox.new("ally")
	inbox.enqueue({"id": "r", "bot_id": "ally", "event_tick": 0, "available_tick": 2,
		"source": "told", "speaker_id": "player", "content": {"type": "test"}})
	inbox.release(2)
	expect(gate.decision(2, inbox).evidence_ids == ["r"], "available context evidence authorizes goal")
	expect(gate.decision(5, inbox).is_empty(), "deadline returns control to fallback")
	expect(not gate.propose(proposal(), 3).ok, "decision ID replay rejected")
	for field in ["context_id", "bot_id", "goal", "target_id", "watch_region_id", "evidence_ids"]:
		var bad: Dictionary = proposal()
		bad[field] = "unknown" if field != "evidence_ids" else ["missing"]
		expect(not gate.propose(bad, 2).ok and gate.decision(2, inbox).is_empty(), "invalid model output drops model control: " + field)
	var fresh = Gate.new("ally", {"cover": ["region_b"]})
	fresh.remember(context())
	expect(not fresh.propose(proposal(), 5).ok, "late model response rejected")
	expect(not fresh.propose(proposal(), 1).ok, "future context rejected")
	var invalid: Dictionary = context()
	invalid.observations[0].available_tick = 3
	expect(not Gate.new("ally", {}).remember(invalid), "future observation cannot enter prompt context")
	invalid = context()
	invalid.observations[0].bot_id = "other"
	expect(not Gate.new("ally", {}).remember(invalid), "foreign observation cannot enter prompt context")
	var late = Inbox.new("ally")
	late.enqueue({"id": "r", "bot_id": "ally", "event_tick": 0, "available_tick": 2,
		"source": "told", "speaker_id": "player", "content": {"type": "test"}})
	late.release(3)
	fresh.propose(proposal(), 3)
	expect(fresh.decision(3, late).is_empty(), "actual late delivery cannot be backdated to model context")
	fresh = Gate.new("ally", {"cover": ["region_b"]})
	fresh.remember(context())
	fresh.propose(proposal(), 2)
	var copied: Dictionary = fresh.active_record()
	copied.intent.target_id = "unseen_enemy"
	expect(fresh.decision(2, inbox).target_id == "cover", "record is a deep copy")
	var code: String = FileAccess.get_file_as_string("res://bots/intent_gate.gd")
	for forbidden in ["get_node(", "get_tree(", "global_position", "FileAccess", "HTTP", "Callable"]:
		expect(not code.contains(forbidden), "pure gate dependency " + forbidden)
	print("PERSON2_INTENT_GATE_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	quit(1 if failed else 0)
