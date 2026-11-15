extends SceneTree
const Policy = preload("res://bots/combat_policy.gd")
const Combat = preload("res://bots/combat_controller.gd")
const Motion = preload("res://bots/motion_controller.gd")
const Navigation = preload("res://tests/person2/motion_navigation.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
class ActorDouble:
	extends Node3D
	var is_alive: bool = true
	var velocity: Vector3 = Vector3.ZERO
	var move_dir: Vector3 = Vector3.ZERO
	func set_move_dir(value: Vector3) -> void: move_dir = value
	func move_toward_point(point: Vector3) -> float:
		move_dir = point - global_position
		return move_dir.length()
class WeaponDouble:
	extends Node3D
	signal reload_started
	signal reload_finished
	var in_mag: int = 25
	var reserve: int = 75
	var shots: int = 0
	var can_shoot: bool = true
	var last_direction: Vector3
	func can_fire() -> bool: return can_shoot and in_mag > 0
	func fire(_origin: Vector3, direction: Vector3, moving: bool, _shooter: Node3D) -> Dictionary:
		if can_fire() and not moving:
			in_mag -= 1
			shots += 1
			last_direction = direction
		return {"collider": self} # Deliberately privileged; must never escape.
	func reload() -> void: reload_started.emit()
var checks: int = 0
var failed: bool = false
func expect(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failed = true
		printerr("FAIL: ", label)
func _initialize() -> void: call_deferred("run")
func observation(id: String, event: int = 0, available: int = 12, lost: bool = false) -> Dictionary:
	var content: Dictionary = {"type": "enemy_lost" if lost else "enemy_aim", "enemy_id": "enemy"}
	if not lost: content["aim_position"] = [0, 1.1, -8]
	return {"id": id, "bot_id": "ally", "event_tick": event, "available_tick": available, "source": "seen", "speaker_id": "sensor", "content": content}
func own() -> Dictionary:
	return {"alive": true, "blind_until_tick": 0, "inside_smoke": false, "view_smoked_off": false, "smoke_view_known": true}
func run() -> void:
	var policy = Policy.new("ally")
	var aim: Dictionary = observation("aim")
	expect(policy.decide(11, [aim], own()).action == "idle", "no fire before delivery")
	var decision: Dictionary = policy.decide(12, [aim], own())
	expect(decision.action == "engage" and decision.evidence_ids == ["aim"], "delivered sight evidence permits engagement")
	decision.aim_position[0] = 999
	expect(policy.decide(12, [aim], own()).aim_position[0] == 0, "decision owns copied last-observed point")
	expect(policy.decide(29, [aim], own()).action == "engage", "contact valid strictly before 30-tick boundary")
	expect(policy.decide(30, [aim], own()).action == "idle", "freshness uses event time and expires at 30-tick boundary")
	expect(Policy.new("ally", 900).decide(30, [aim], own()).action == "idle", "configuration cannot extend freshness beyond agreed 30 ticks")
	var lost: Dictionary = observation("lost", 1, 20, true)
	expect(policy.decide(19, [aim, lost], own()).action == "engage", "future loss cannot affect earlier decision")
	expect(policy.decide(20, [aim, lost], own()).action == "idle", "delivered loss invalidates contact")
	var reacquired: Dictionary = observation("reacquired", 2, 21)
	expect(policy.decide(21, [lost, reacquired, aim], own()).evidence_ids == ["reacquired"], "event ordering handles out-of-order delivery")
	expect(policy.decide(22, [reacquired, observation("tie_loss", 2, 22, true)], own()).action == "idle", "loss wins equal-event tie")
	for key in ["inside_smoke", "view_smoked_off"]:
		var state: Dictionary = own()
		state[key] = true
		expect(policy.decide(12, [aim], state).action == "idle", "own " + key + " suppresses fire")
	for key in ["alive", "smoke_view_known"]:
		var state: Dictionary = own()
		state[key] = false
		expect(policy.decide(12, [aim], state).action == "idle", "own " + key + " gate suppresses fire")
	var blind: Dictionary = own()
	blind.blind_until_tick = 13
	expect(policy.decide(12, [aim], blind).action == "idle", "current own blindness suppresses fire")
	for wrong in ["heard", "told", 7]:
		var bad: Dictionary = aim.duplicate(true)
		bad.source = wrong
		expect(policy.decide(12, [bad], own()).action == "idle", "unseen testimony/sound cannot become exact aim: " + str(wrong))
	var bad: Dictionary = aim.duplicate(true)
	bad.bot_id = "other"
	expect(policy.decide(12, [bad], own()).action == "idle", "foreign evidence cannot aim")
	bad = aim.duplicate(true)
	bad.content.aim_position = [NAN, 0, 0]
	expect(policy.decide(12, [bad], own()).action == "idle", "nonfinite aim fails closed")
	var hidden := Node3D.new()
	root.add_child(hidden)
	var before: Dictionary = policy.decide(12, [aim], own())
	hidden.position = Vector3(300, 20, -90)
	expect(policy.decide(12, [aim], own()) == before, "unseen live-node perturbation cannot change combat decision")
	var source: String = FileAccess.get_file_as_string("res://bots/combat_policy.gd")
	for forbidden in ["get_node(", "get_tree(", "global_position", "Weapon", "ActorBase", "query_path", "PhysicsServer"]:
		expect(not source.contains(forbidden), "pure combat policy excludes " + forbidden)
	var actor := ActorDouble.new()
	var weapon := WeaponDouble.new()
	root.add_child(actor)
	actor.add_child(weapon)
	var combat = Combat.new("ally", actor, weapon)
	actor.velocity = Vector3(6, 0, 0)
	var output: Dictionary = combat.step(12, policy.decide(12, [aim], own()))
	expect(output.halt_movement and output.reason == "stopping_to_shoot" and weapon.shots == 0, "actual movement velocity blocks firing")
	actor.velocity = Vector3.ZERO
	output = combat.step(13, policy.decide(13, [aim], own()))
	expect(output.reason == "rifle_fired" and weapon.shots == 1 and weapon.in_mag == 24, "stopped actor fires its own rifle")
	expect(not output.has("collider") and not output.has("position"), "physical hit truth stays out of telemetry")
	expect(weapon.last_direction.angle_to(Vector3(0, -0.5, -8).normalized()) < deg_to_rad(3), "aim error stays around copied observed point")
	expect(not combat.step(13, policy.decide(13, [aim], own())).ok and weapon.shots == 1, "duplicate physical tick cannot fire twice")
	weapon.can_shoot = false
	expect(combat.step(14, policy.decide(14, [aim], own())).reason == "rifle_cooldown" and weapon.shots == 1, "shared weapon rate limit respected")
	weapon.in_mag = 0
	output = combat.step(15, policy.decide(15, [aim], own()))
	expect(output.reason == "reloading" and weapon.shots == 1, "empty rifle requests shared reload")
	weapon.in_mag = 25
	weapon.can_shoot = true
	weapon.reload_finished.emit()
	expect(combat.step(16, policy.decide(16, [aim], own())).reason == "rifle_fired", "shared reload completion permits fire")
	actor.rotation.y = PI
	expect(combat.step(17, policy.decide(17, [aim], own())).reason == "aiming_last_observed_point", "large angle turns before shooting")
	expect(not combat.step(48, before).ok, "stale/foreign-tick physical decision rejected")
	combat.dispose()
	# Real motion dispatcher owns lateral facing and the combat stop/resume.
	actor.position = Vector3.ZERO
	actor.rotation = Vector3.ZERO
	var nav := Navigation.new()
	root.add_child(nav)
	var markers: Dictionary = {"home": {"position": [0, 0, 0], "watch_points": {"angle": [0, 1.6, -8]}},
		"peek": {"position": [2, 0, 0], "watch_points": {"angle": [0, 1.6, -8]}}}
	var motion = Motion.new("ally", actor, nav, markers, {"entry": {"stage_marker_id": "home", "route_marker_ids": ["peek"], "watch_region_id": "angle"}}, 0.25, 3)
	var inbox = Inbox.new("ally")
	inbox.enqueue(observation("request", 0, 1))
	inbox.release(1)
	var intent: Dictionary = {"bot_id": "ally", "command_id": "swing", "tick": 1, "op": "start_swing", "target_id": "entry", "evidence_ids": ["request"]}
	var active: Dictionary = {"message_id": "swing"}
	output = motion.step(1, {}, {"errors": [], "intents": [intent]}, active, inbox)
	expect(output.state == "moving" and actor.move_dir.x > 0 and absf(actor.move_dir.z) < 0.001, "released swing moves laterally: " + str(output))
	expect(absf(actor.rotation.y) < 0.001, "lateral swing keeps facing authored angle instead of travel direction")
	combat = Combat.new("ally", actor, weapon)
	motion.attach_combat(combat)
	inbox.release(2)
	output = motion.step(2, {}, {"errors": [], "intents": []}, active, inbox, policy.decide(2, [observation("request", 0, 1)], own()))
	expect(output.state == "engaging" and actor.move_dir == Vector3.ZERO, "delivered contact stops swing through sole movement owner: " + str(output))
	expect(motion.take_feedback().is_empty(), "stopping to engage is not route completion")
	inbox.release(10)
	motion.step(10, {}, {"errors": [], "intents": []}, active, inbox, policy.decide(10, [observation("request", 0, 1)], own()))
	inbox.release(11)
	output = motion.step(11, {}, {"errors": [], "intents": []}, active, inbox, policy.decide(11, [], own()))
	expect(output.state == "moving" and actor.move_dir.x > 0, "contact loss resumes unfinished route without false stuck: " + str(output))
	actor.position.x = 2
	inbox.release(12)
	motion.step(12, {}, {"errors": [], "intents": []}, active, inbox)
	expect(motion.take_feedback() == [{"command_id": "swing", "phase": "completed"}], "only actual peek endpoint completes command")
	combat.dispose()
	actor.free()
	nav.free()
	hidden.free()
	print("PERSON2_COMBAT_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	quit(1 if failed else 0)
