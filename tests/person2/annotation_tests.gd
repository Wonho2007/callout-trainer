extends SceneTree
const Policy = preload("res://bots/annotation_policy.gd")
var checks: int = 0
var failed: bool = false

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)

func _initialize() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/fnc_prx_lotus_toronto2024_gf.json"))
	var own: Dictionary = {"alive": true, "hp": 70, "blinded": false, "engaged": false, "marker_id": "b_pit",
		"reachable_marker_ids": ["b_main", "b_cubby", "b_heaven", "b_upper", "b_pit", "c_link", "a_link"]}
	var ally = Policy.new("ally", source.timeline)
	expect(ally.decide(0, [], own).target_id == "b_pit", "ally baseline starts at Pit")
	ally.set_scenario_tick(120)
	expect(ally.decide(120, [], own).target_id == "b_cubby", "annotation redirects ally toward Cubby at +2s")
	expect(ally.take_utility().is_empty(), "smoke waits for physical staging")
	own.marker_id = "b_cubby"
	ally.decide(121, [], own)
	var throws: Array = ally.take_utility()
	expect(throws.size() == 1 and throws[0].region == "c_link", "staged ally throws annotated C Link smoke")
	ally.decide(122, [], own)
	expect(ally.take_utility().is_empty(), "baseline smoke cannot duplicate")
	ally.set_scenario_tick(1140)
	ally.decide(1140, [], own)
	throws = ally.take_utility()
	expect(throws.size() == 1 and throws[0].region == "b_main", "+18s initial cooldown allows +19s Main smoke")
	ally.set_scenario_tick(1380)
	expect(ally.decide(1380, [], own).target_id == "b_main", "ally pushes Main at +23s")
	ally.set_scenario_tick(1560)
	expect(ally.decide(1560, [], own).target_id == "b_cubby", "ally returns Cubby at +26s")
	var report: Dictionary = {"id": "call", "bot_id": "ally", "source": "told", "event_tick": 1560, "available_tick": 1578,
		"content": {"type": "comms", "message": {"kind": "report"}}}
	expect(not ally.decide(1577, [report], own).is_empty(), "undelivered call cannot interrupt baseline")
	expect(ally.decide(1578, [report], own).is_empty() and ally.snapshot().deviated, "delivered call hands ally back to belief planner")
	var invalid: Dictionary = report.duplicate(true)
	invalid.bot_id = "other"
	var unaffected = Policy.new("ally", source.timeline)
	expect(not unaffected.decide(1578, [invalid], own).is_empty(), "foreign report cannot alter baseline")
	var commanded = Policy.new("ally", source.timeline)
	commanded.consider_player_plan({"evidence_ids": ["command"]})
	expect(commanded.decide(0, [], own).is_empty(), "accepted command ends baseline so it cannot overwrite player intent")
	var retaker = Policy.new("kaajak", source.timeline, 1380)
	own.hp = 150
	own.marker_id = "c_link"
	expect(retaker.decide(0, [], own).target_id == "c_link", "Raze holds recorded C Link rather than immediately rushing Pit")
	retaker.set_scenario_tick(1680)
	retaker.decide(300, [], own)
	throws = retaker.take_utility()
	expect(throws.size() == 1 and throws[0].action == "reference_grenade" and throws[0].region == "b_pit", "Raze throws once into Pit at +28s")
	var chronicle = Policy.new("chronicle", source.timeline, 1380)
	expect(chronicle.decide(0, [], own).target_id == "b_heaven", "Chronicle begins on recorded Heaven line")
	chronicle.set_scenario_tick(1800)
	expect(chronicle.decide(420, [], own).target_id == "b_upper", "Chronicle follows annotated Upper destination at +30s")
	var sight: Dictionary = {"id": "contact", "bot_id": "chronicle", "source": "seen", "event_tick": 0, "available_tick": 18,
		"content": {"type": "enemy_seen", "enemy_id": "player", "region_id": "b_heaven"}}
	var reactive = Policy.new("chronicle", source.timeline, 1380)
	expect(reactive.decide(17, [sight], own).target_id == "b_heaven", "future sight cannot trigger deviation")
	var response: Dictionary = reactive.decide(18, [sight], own)
	expect(response.target_id == "a_link" and response.evidence_ids == ["contact"], "actually seen off-baseline player activates reactive flank")
	var unchanged = Policy.new("chronicle", source.timeline, 1380)
	sight.content.region_id = "a_link"
	expect(unchanged.decide(18, [sight], own).target_id == "b_heaven" and not unchanged.snapshot().deviated, "player at annotated A Link preserves baseline")
	var blind = Policy.new("kaajak", source.timeline, 1380)
	blind.set_scenario_tick(1680)
	own.blinded = true
	blind.decide(300, [], own)
	expect(blind.take_utility().is_empty(), "blind bot cannot release timed grenade")
	own.blinded = false
	own.alive = false
	expect(blind.decide(301, [], own).goal == "stop" and blind.take_utility().is_empty(), "dead bot never throws utility")
	print("PERSON2_ANNOTATION_", "FAIL" if failed else "PASS", " checks=", checks)
	quit(1 if failed else 0)
