extends Node
# Privileged fixture only. Uses the inherited current map and shared mechanics;
# manually clocks the real runtime so observation/event cutoffs are exact.
const Data = preload("res://perception/plain_data.gd")
const Runtime = preload("res://bots/teammate_runtime.gd")
const SceneSensor = preload("res://perception/scene_sensor.gd")
const Belief = preload("res://belief/region_belief.gd")
var checks: int = 0
var failed: bool = false
var scene: Node3D
var runtime: Node
var enemy: CharacterBody3D
var bot: CharacterBody3D
var player: CharacterBody3D
var deliveries: Array = []
var contexts: Array = []
var decisions: Array = []
var yaw: float = -PI / 2.0

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)

func fresh(perception_seed: int = -1) -> void:
	if is_instance_valid(scene.runtime):
		scene.runtime.free()
	var settings: Dictionary = scene.get("_scenario")
	runtime = Runtime.new()
	scene.add_child(runtime)
	scene.runtime = runtime
	runtime.configure("ally", bot, scene.builder, Belief.new("ally", settings.planner.regions, ["enemy"]),
		settings.planner, settings.motion_markers, settings.entries, 900)
	runtime.attach_perception(SceneSensor.new("ally", bot, scene.builder, scene.utility,
		{"enemy": enemy}, settings.perception, int(settings.perception_seed) if perception_seed < 0 else perception_seed, 900, player, settings.player_entry_sensing))
	runtime.set_physics_process(false)
	runtime.observation_delivered.connect(func(o: Dictionary, tick: int): deliveries.append({"observation": o, "tick": tick}))
	runtime.policy_context_ready.connect(func(c: Dictionary): contexts.append(c))
	runtime.decision_recorded.connect(func(d: Dictionary): decisions.append(d))
	deliveries.clear()
	contexts.clear()
	decisions.clear()

func advance(count: int, move_enemy: bool = false, move_player: bool = false) -> void:
	for i in count:
		if move_enemy:
			enemy._physics_process(1.0 / 60.0)
		if move_player:
			player._physics_process(1.0 / 60.0)
		await get_tree().physics_frame
		await get_tree().process_frame
		bot.rotation.y = yaw
		runtime._physics_process(1.0 / 60.0)

func count_since(source: String, cutoff: int, kind: String = "") -> int:
	var total: int = 0
	for item in deliveries:
		var o: Dictionary = item.observation
		if source == "seen" and o.content.get("type") not in ["enemy_seen", "enemy_seen_unknown_region"]:
			continue
		if o.source == source and o.event_tick >= cutoff and (kind.is_empty() or o.content.get("sound_kind") == kind):
			total += 1
	return total

func typed_since(kind: String, cutoff: int = 0) -> Array:
	var output: Array = []
	for item in deliveries:
		if item.observation.content.get("type") == kind and item.observation.event_tick >= cutoff:
			output.append(item)
	return output

func next_tick() -> int:
	return runtime.current_tick() + 1

func verify_natural_smoke() -> void:
	# Exercise actual shared ground deployment/activation/expiry, without writing
	# is_active. Shorten only this disposable fixture's ability definition.
	var definitions: Dictionary = scene.utility.get("_defs")
	var original_duration: float = float(definitions.smoke.duration_s)
	var original_player_position: Vector3 = player.global_position
	# Keep the real player capsule out of the baseline LOS; actor occlusion is
	# intentional and must not make a smoke test pass for the wrong reason.
	player.global_position = Vector3(-4, 0, 12.3)
	definitions.smoke.duration_s = 1.5
	for placement in ["between", "observer_inside", "enemy_inside"]:
		bot.global_position = Vector3(-4.5, 0, 11.5)
		enemy.global_position = Vector3(4.5, 0, 11.5)
		yaw = -PI / 2.0
		fresh()
		# Initial recognition is delivered; the refresh at tick 35 is still
		# legitimately pending when the smoke activates immediately afterward.
		await advance(36)
		expect(count_since("seen", 0) > 0, placement + ": enemy is actually visible before smoke")
		var at := Vector3(0, 0, 11.5)
		if placement == "observer_inside":
			at.x = bot.global_position.x
		elif placement == "enemy_inside":
			at.x = enemy.global_position.x
		var smoke: Node3D = scene.utility.throw_smoke(at)
		while not smoke.is_active:
			await advance(1)
		var cutoff: int = next_tick()
		var eye: Vector3 = bot.global_position + Vector3.UP * 1.6
		var all_blocked: bool = true
		for height in [1.6, 0.9, 0.2]:
			all_blocked = all_blocked and scene.utility.segment_blocked_by_smoke(eye, enemy.global_position + Vector3.UP * height)
		expect(all_blocked, placement + ": naturally active shared smoke intersects every target sight sample")
		if placement == "between":
			expect(not smoke.contains_point(eye) and not smoke.contains_point(enemy.global_position + Vector3.UP * 1.6), "both actors outside smoke still cannot see through its volume")
		else:
			var endpoint: Vector3 = eye if placement == "observer_inside" else enemy.global_position + Vector3.UP * 1.6
			expect(smoke.contains_point(endpoint), placement + ": tested endpoint is genuinely inside active smoke")
		await advance(32)
		expect(count_since("seen", cutoff) == 0, placement + ": smoke prevents all newly sampled/delivered sightings")
		expect(typed_since("enemy_aim", cutoff).is_empty() and typed_since("enemy_lost", cutoff).size() == 1, placement + ": smoke produces one delayed aim loss and no fresh torso coordinates")
		var own_smoke: Dictionary = runtime.snapshot().own_perception
		expect(own_smoke.inside_smoke if placement == "observer_inside" else (own_smoke.view_smoked_off and not own_smoke.inside_smoke), placement + ": own smoke status distinguishes inside from obstructed forward view")
		var smoke_panel: PanelContainer = scene.get("_info_panel")
		smoke_panel.update_information(runtime.snapshot())
		expect(smoke_panel.text_for("Smoke").contains("IN SMOKE" if placement == "observer_inside" else "SMOKED OFF"), placement + ": HUD explicitly reflects smoke blocking the teammate")
		enemy.global_position.x -= 0.2
		await advance(1)
		expect(runtime.snapshot().own_perception == own_smoke, placement + ": smoke knowledge is independent of unseen opponent position")
		var pending_arrived: bool = false
		for item in deliveries:
			var observation: Dictionary = item.observation
			pending_arrived = pending_arrived or (observation.source == "seen" and observation.event_tick < cutoff and item.tick >= cutoff)
		expect(pending_arrived, placement + ": legitimate sight sampled before smoke may finish its reaction delay")
		var newest: int = -1
		for observation in runtime.snapshot().observations:
			if observation.content.get("type") in ["enemy_seen", "enemy_seen_unknown_region"]:
				newest = maxi(newest, observation.event_tick)
		await advance(20)
		var unchanged: bool = true
		for observation in runtime.snapshot().observations:
			if observation.content.get("type") in ["enemy_seen", "enemy_seen_unknown_region"]:
				unchanged = unchanged and observation.event_tick <= newest and observation.event_tick < cutoff
		expect(unchanged, placement + ": last-seen memory cannot refresh through smoke")
		var panel: PanelContainer = scene.get("_info_panel")
		panel.update_information(runtime.snapshot())
		expect(panel.text_for("Sight").contains("enemy in corridor") and panel.text_for("Sight").contains("ago"), placement + ": HUD preserves explicitly aged last-seen memory")
		while is_instance_valid(smoke):
			await advance(1)
		var cleared: int = next_tick()
		await advance(25)
		expect(count_since("seen", cleared) > 0, placement + ": real smoke expiry permits recognition again after exposure/reaction delay")
		expect(not typed_since("enemy_aim", cleared).is_empty(), placement + ": real smoke expiry restores delayed visible torso evidence")
		smoke_panel.update_information(runtime.snapshot())
		expect(not runtime.snapshot().own_perception.inside_smoke and not runtime.snapshot().own_perception.view_smoked_off and smoke_panel.text_for("Smoke") == "Smoke: clear on watched angle", placement + ": smoke status clears automatically on actual expiry")
	# A new smoke on the far side of the actual corridor end wall is not known
	# simply because the privileged utility registry contains it.
	fresh()
	var hidden_smoke: Node3D = scene.utility.throw_smoke(Vector3(10, 0, 11.5))
	await advance(5)
	expect(hidden_smoke.is_active and not runtime.snapshot().own_perception.view_smoked_off, "own forward smoke knowledge cannot see through the first solid wall")
	while is_instance_valid(hidden_smoke):
		await advance(1)
	definitions.smoke.duration_s = original_duration
	player.global_position = original_player_position

func verify_aim_delivery() -> void:
	bot.global_position = Vector3(-2, 0, 11.5)
	enemy.global_position = Vector3(2, 0, 11.5)
	player.global_position = Vector3(-4, 0, 11.5)
	yaw = -PI / 2.0
	fresh()
	await advance(4)
	expect(typed_since("enemy_aim").is_empty(), "torso recognition cannot bypass reaction delay")
	var observed_torso: Vector3 = enemy.global_position + Vector3.UP * 0.9
	var old_point: Array = [observed_torso.x, observed_torso.y, observed_torso.z]
	var cutoff: int = next_tick()
	enemy.global_position = Vector3(-4, 0, 3)
	await advance(27)
	var aims: Array = typed_since("enemy_aim")
	var losses: Array = typed_since("enemy_lost")
	expect(not aims.is_empty() and aims[0].observation.content == {"type": "enemy_aim", "enemy_id": "enemy", "aim_position": old_point}, "delivered aim contains only the actual last-observed torso point")
	expect(typed_since("enemy_aim", cutoff).is_empty() and losses.size() == 1, "unseen move cannot update aim and produces only one delayed loss")
	if not aims.is_empty() and not losses.is_empty():
		expect(aims[0].tick <= losses[0].tick and losses[0].observation.content == {"type": "enemy_lost", "enemy_id": "enemy"}, "loss is causally delivered after its observed aim without revealing hidden cause/location")
		expect(aims[0].observation.available_tick <= aims[0].tick and losses[0].observation.available_tick <= losses[0].tick, "aim/loss signals honor actual availability")
		var id: String = aims[0].observation.id
		aims[0].observation.content.aim_position[0] = 99999
		var copied: bool = false
		for observation in runtime.snapshot().observations:
			copied = copied or (observation.id == id and observation.content.get("aim_position") == old_point)
		expect(copied, "delivered aim arrays cannot mutate the private inbox")
	expect(Data.valid(contexts) and Data.valid(runtime.snapshot().observations), "aim/loss context content is recursively plain copied data")
	# A low world blocker hides the torso/feet but leaves the head genuinely
	# visible: region recognition must not grant an unseen torso coordinate.
	enemy.global_position = Vector3(2, 0, 11.5)
	var cover := StaticBody3D.new()
	cover.collision_layer = 1
	cover.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.5, 1.4, 1)
	collision.shape = shape
	cover.add_child(collision)
	scene.add_child(cover)
	cover.global_position = Vector3(0, 0.7, 11.5)
	fresh()
	await advance(26)
	expect(count_since("seen", 0) > 0, "exposed head still produces a legitimate regional sighting")
	expect(typed_since("enemy_aim").is_empty() and typed_since("enemy_lost").is_empty(), "head-only visibility never invents a hidden torso point or unseen target loss")
	cover.free()
	await advance(2)
	fresh()
	await advance(32)
	aims = typed_since("enemy_aim")
	var refresh: bool = aims.size() >= 2
	for i in range(1, aims.size()):
		refresh = refresh and aims[i].observation.event_tick - aims[i - 1].observation.event_tick >= 6
	expect(refresh, "visible torso updates respect the six-tick sampling cadence")
	cutoff = next_tick()
	yaw = PI / 2.0
	await advance(25)
	expect(typed_since("enemy_aim", cutoff).is_empty() and typed_since("enemy_lost", cutoff).size() == 1, "looking away invalidates aim through one delayed loss")
	yaw = -PI / 2.0
	await advance(26)
	var flash: Node3D = scene.utility.throw_flash(Vector3(0, 1.6, 11.5), Vector3.ZERO)
	flash.freeze = true
	while not flash.is_active:
		await advance(1)
	cutoff = runtime.current_tick()
	var blind_until: int = runtime.snapshot().own_perception.blind_until_tick
	await advance(24)
	expect(typed_since("enemy_aim", cutoff).is_empty() and typed_since("enemy_lost", cutoff).size() == 1, "actual flash stops fresh aim and queues aim loss")
	await advance(maxi(1, blind_until - runtime.current_tick() + 25))
	expect(not typed_since("enemy_aim", blind_until).is_empty(), "torso aim reacquires only after blindness, exposure and delayed availability")

func verify_aim_reacquisition_order() -> void:
	# Reacquire before earlier aim/loss envelopes finish their random delays.
	# Real map collision and the real inbox must preserve each lock's lifetime.
	bot.global_position = Vector3(-2, 0, 11.5)
	player.global_position = Vector3(-4, 0, 11.5)
	yaw = -PI / 2.0
	for seed_value in [7, 73, 191]:
		enemy.global_position = Vector3(2, 0, 11.5)
		fresh(seed_value)
		for cycle in 5:
			enemy.global_position = Vector3(2, 0, 11.5)
			await advance(3)
			if cycle == 0:
				expect(typed_since("enemy_aim").is_empty(), "rapid lock waits for reaction delay seed=" + str(seed_value))
			enemy.global_position = Vector3(-4, 0, 3)
			await advance(1)
		await advance(24)
		var sequence: Array = []
		var legal: bool = true
		var prior_event: int = -1
		var ids: Dictionary = {}
		for item in deliveries:
			var observation: Dictionary = item.observation
			if observation.content.get("type") not in ["enemy_aim", "enemy_lost"]:
				continue
			sequence.append(observation.content.type)
			legal = legal and observation.event_tick > prior_event and observation.available_tick <= item.tick and not ids.has(observation.id)
			prior_event = observation.event_tick
			ids[observation.id] = true
		expect(sequence == ["enemy_aim", "enemy_lost", "enemy_aim", "enemy_lost", "enemy_aim", "enemy_lost", "enemy_aim", "enemy_lost", "enemy_aim", "enemy_lost"], "rapid reacquisition delivers all five aim/loss pairs in causal order seed=" + str(seed_value))
		expect(legal, "rapid reacquisition preserves unique evidence and event/delivery provenance seed=" + str(seed_value))
		var loss_count: int = typed_since("enemy_lost").size()
		await advance(20)
		expect(typed_since("enemy_lost").size() == loss_count and typed_since("enemy_aim", 20).is_empty(), "continued hidden state cannot renew loss or aim seed=" + str(seed_value))
	# A target dying after a recognized but pending aim grants no kill/position
	# knowledge. Only the ordinary delayed loss of usable torso sight may leave.
	enemy.global_position = Vector3(2, 0, 11.5)
	fresh()
	await advance(3)
	var cutoff: int = next_tick()
	enemy.health.apply_damage(enemy.health.max_hp)
	enemy.global_position = Vector3(-4, 0, 3)
	await advance(25)
	expect(not enemy.is_alive and typed_since("enemy_aim").size() == 1 and typed_since("enemy_aim", cutoff).is_empty(), "death preserves only the legitimate pre-death pending aim")
	var losses: Array = typed_since("enemy_lost", cutoff)
	expect(losses.size() == 1 and losses[0].observation.content == {"type": "enemy_lost", "enemy_id": "enemy"}, "dead target yields one delayed loss without hidden death/position disclosure")
	enemy.health.reset()
	enemy.is_alive = true

func verify_player_entry() -> void:
	var definitions: Dictionary = scene.utility.get("_defs")
	var original_duration: float = float(definitions.smoke.duration_s)
	definitions.smoke.duration_s = 1.5
	for obstruction in ["clear", "smoke", "blind", "behind"]:
		bot.global_position = Vector3(-2, 0, 11.5)
		enemy.global_position = Vector3(-4, 0, 3)
		player.global_position = Vector3(0, 0, 10.3)
		player.velocity = Vector3.ZERO
		player.rotation.y = 0
		yaw = atan2(-2.0, 3.5) if obstruction != "behind" else PI
		fresh()
		var issued: int = next_tick()
		runtime.submit_comm({"schema_version": "comms.v1", "message_id": "live-follow", "speaker_id": "player", "recipient_id": "ally",
			"issued_tick": issued, "expires_tick": issued + 500, "kind": "command",
			"payload": {"action": "swing_together", "target_id": "entry", "timing": {"mode": "follow_player"}}})
		await advance(24)
		expect(runtime.snapshot().active_command.get("phase") == "ready", obstruction + ": actual delayed follow-player command stages first")
		var smoke: Node3D
		if obstruction == "smoke":
			smoke = scene.utility.throw_smoke(Vector3(0, 0, 9))
		if obstruction == "blind":
			var forward: Vector3 = Vector3(2, 0, -3.5).normalized()
			var flash: Node3D = scene.utility.throw_flash(bot.global_position + Vector3.UP * 1.6 + forward * 2, Vector3.ZERO)
			flash.freeze = true
			while not flash.is_active:
				await advance(1)
			await advance(1)
		var start: int = next_tick()
		Input.action_press("walk")
		Input.action_press("move_forward")
		for i in 120:
			if player.global_position.z < 9.99:
				break
			await advance(1, false, true)
		await advance(3, false, true)
		Input.action_release("move_forward")
		Input.action_release("walk")
		player.set_move_dir(Vector3.ZERO)
		player.velocity = Vector3.ZERO
		expect(player.global_position.z < 10, obstruction + ": real player controller actually crosses into entry")
		if obstruction == "smoke":
			var covered: bool = is_instance_valid(smoke) and smoke.is_active
			for height in [1.6, 0.9, 0.2]:
				covered = covered and scene.utility.segment_blocked_by_smoke(bot.global_position + Vector3.UP * 1.6, player.global_position + Vector3.UP * height)
			expect(covered, "entry smoke covers head, torso and feet rather than exposing an edge sample")
		expect(runtime.snapshot().active_command.get("phase") == "ready", obstruction + ": actual entry movement cannot release before sensory delay")
		await advance(25)
		var entries: Array = []
		for item in deliveries:
			if item.observation.content.get("type") == "player_entry" and item.observation.event_tick >= start:
				entries.append(item)
		if obstruction == "clear":
			expect(not entries.is_empty() and runtime.snapshot().active_command.get("phase") == "executing", "actual quiet visible player entry releases the staged command after delivery")
			if not entries.is_empty():
				var entry: Dictionary = entries[0].observation
				expect(entry.source == "seen" and entry.content == {"type": "player_entry", "actor_id": "player", "entry_id": "entry"} and entry.available_tick <= entries[0].tick, "live entry producer emits exact agreed plain payload with actual availability")
				expect(entry.id in runtime.snapshot().active_command.evidence_ids, "live follow-player release cites its delivered entry evidence")
				scene.get("_info_panel").update_information(runtime.snapshot())
				expect(scene.get("_info_panel").text_for("Entry").contains("Player entry: entry"), "HUD shows only actually delivered player-entry movement")
		else:
			expect(entries.is_empty() and runtime.snapshot().active_command.get("phase") == "ready", obstruction + ": obscured/unseen movement cannot trigger follow-player release")
		if obstruction == "smoke":
			while is_instance_valid(smoke):
				await advance(1)
			expect(runtime.snapshot().active_command.get("phase") == "ready", "smoke clearing does not invent entry motion from a stationary player")
		if obstruction == "blind":
			await advance(maxi(1, int(runtime.snapshot().own_perception.blind_until_tick) - runtime.current_tick() + 1))
	definitions.smoke.duration_s = original_duration

func run(host: Node3D) -> void:
	scene = host
	bot = scene.teammate
	enemy = scene.get("_target")
	player = scene.get("_player")
	bot.set_physics_process(false)
	enemy.set_physics_process(false)
	player.set_physics_process(false)
	# Keep the shared round timer from ending this longer fixture.
	scene.get("_spike").set_physics_process(false)
	bot.global_position = Vector3(-2, 0, 11.5)
	enemy.global_position = Vector3(2, 0, 11.5)
	player.global_position = Vector3(-4, 0, 11.5)
	fresh()
	await advance(4)
	expect(deliveries.is_empty(), "visible target cannot reach policy before reaction delay")
	await advance(22)
	expect(count_since("seen", 0) == 1, "real corridor target produces one delayed sighting")
	var first_item: Dictionary = typed_since("enemy_seen")[0]
	var first: Dictionary = first_item.observation
	expect(first.content == {"type": "enemy_seen", "enemy_id": "enemy", "region_id": "corridor"}, "sighting contains agreed region content only")
	expect(first_item.tick == first.available_tick and first.available_tick - first.event_tick >= 12 and first.available_tick - first.event_tick <= 18, "seeded sight delivery honors actual availability tick")
	await advance(5)
	var visible_context: Dictionary = contexts[-1].duplicate(true)
	expect(first.id in visible_context.belief.evidence_ids, "due live sighting reaches actual Person 3 belief evidence")
	var candidate: Dictionary = {"context_id": visible_context.context_id, "decision_id": "sight-backed", "bot_id": "ally",
		"goal": "hold", "target_id": "home", "watch_region_id": "entry", "evidence_ids": [first.id]}
	expect(runtime.submit_intent(candidate).ok, "model intent may cite sighting actually delivered in captured context")
	candidate.decision_id = "invented-evidence"
	candidate.evidence_ids = ["not-delivered"]
	expect(not runtime.submit_intent(candidate).ok, "model intent cannot cite missing sensory evidence")
	for observation in contexts[-1].observations:
		if observation.id == first.id:
			observation.content.region_id = "tampered"
	var isolated: bool = false
	for observation in runtime.snapshot().observations:
		isolated = isolated or (observation.id == first.id and observation.content.get("region_id") == "corridor")
	expect(isolated, "mutating emitted context cannot change private sensory inbox")
	var evidence_legal: bool = true
	for record in decisions:
		for id in record.plan.get("decision", {}).get("evidence_ids", []):
			var found: bool = false
			for item in deliveries:
				found = found or (item.observation.id == id and item.tick <= record.tick and item.observation.available_tick <= record.tick)
			evidence_legal = evidence_legal and found
	expect(evidence_legal, "every sight-driven decision cites evidence delivered by its decision tick")
	# Hide behind actual corridor-front/hall geometry, retaining pending evidence.
	var cutoff: int = next_tick()
	enemy.global_position = Vector3(-4, 0, 3)
	var wall_ray := PhysicsRayQueryParameters3D.create(bot.global_position + Vector3.UP * 1.6,
		enemy.global_position + Vector3.UP * 1.6, 1)
	expect(not scene.get_world_3d().direct_space_state.intersect_ray(wall_ray).is_empty(), "wall fixture uses real current-map collision, independently of FOV")
	await advance(45)
	expect(count_since("seen", cutoff) == 0, "current map wall prevents newly sampled sightings")
	# Wrong, uncorroborated testimony still gets accepted and affects coverage.
	# Fresh belief isolates acceptance from Person 3's known correction/weighting gap.
	fresh()
	var issued: int = next_tick()
	runtime.submit_comm({"schema_version": "comms.v1", "message_id": "wrong-but-valid", "speaker_id": "player", "recipient_id": "ally",
		"issued_tick": issued, "expires_tick": issued + 300, "kind": "report",
		"payload": {"action": "report_enemy", "region_id": "room", "count": 1, "hedge": "sure"}})
	await advance(24)
	expect(count_since("told", issued) == 1 and runtime.snapshot().plan.decision.target_id == "cover", "valid wrong player report affects coverage without visual corroboration")
	# Active smoke versus falling raw smoke collider from actual UtilitySystem.
	enemy.global_position = Vector3(2, 0, 11.5)
	var smoke: Node3D = scene.utility.throw_smoke(Vector3(0, 8, 11.5))
	smoke.duration_s = 0.2
	smoke.set_process(false)
	# Put its raw collider across the sightline while still inactive. This
	# deliberately tests the shared layer-16 collider/active geometry distinction.
	smoke.get("_body").position = Vector3.ZERO
	expect(not smoke.is_active, "shared falling smoke starts inactive")
	cutoff = next_tick()
	await advance(24)
	expect(count_since("seen", cutoff) > 0, "inactive falling smoke collider does not block recognition")
	expect(not runtime.snapshot().own_perception.inside_smoke and not runtime.snapshot().own_perception.view_smoked_off, "inactive falling smoke is not reported as own smoke obstruction")
	smoke.is_active = true
	cutoff = next_tick()
	await advance(40)
	expect(count_since("seen", cutoff) == 0, "active shared smoke blocks all target sample points")
	smoke.is_active = false
	cutoff = next_tick()
	await advance(25)
	expect(count_since("seen", cutoff) > 0, "recognition resumes after smoke occlusion ends")
	# Finish the real fall coroutine before disabling the fixture blocker; do
	# not strand an awaiting tween by freeing the effect partway through it.
	while not smoke.is_active:
		await advance(1)
	smoke.is_active = false
	# Shared flash: actual fuse, real LOS, then duration gates recognition.
	var flash: Node3D = scene.utility.throw_flash(Vector3(0, 1.6, 11.5), Vector3.ZERO)
	flash.freeze = true
	while not flash.is_active:
		await advance(1)
	await advance(1)
	var blind_until: int = runtime.snapshot().own_perception.blind_until_tick
	expect(blind_until > runtime.current_tick(), "shared visible flash blinds the teammate")
	cutoff = next_tick()
	await advance(24)
	expect(count_since("seen", cutoff) == 0, "blind blocks new sightings while pre-blind delayed evidence remains legal")
	await advance(maxi(1, blind_until - runtime.current_tick() + 25))
	expect(count_since("seen", blind_until) > 0, "sight resumes only after blind duration and exposure")
	# Position behind the hall wall: flash fails LOS; wave intentionally ignores it.
	var blocked_at := Vector3(-2, 1.6, 8)
	yaw = 0.0
	flash = scene.utility.throw_flash(blocked_at, Vector3.ZERO)
	flash.freeze = true
	while not flash.is_active:
		await advance(1)
	await advance(1)
	expect(runtime.snapshot().own_perception.blind_until_tick <= runtime.current_tick(), "flash behind real map wall cannot blind")
	var wave: Node3D = scene.utility.throw_blind_wave(blocked_at, Vector3.BACK)
	# Actual travel through the wall, not a fixture-written is_active flag.
	bot.rotation.y = yaw
	var wave_tick: int = next_tick()
	await advance(1)
	var expected_duration: float = wave.passing_blind_duration_for(bot.global_position + Vector3.UP * 1.6, Vector3.FORWARD, false) + 1.0
	expect(runtime.snapshot().own_perception.blind_until_tick == wave_tick + int(ceil(expected_duration * 60.0)), "explicit blind-wave registry applies through-wall duration plus shared extra second")
	expect(not wave.is_active and runtime.snapshot().own_perception.blind_until_tick > runtime.current_tick(), "actual traveling wave blinds before endpoint detonation")
	var wave_blind_until: int = runtime.snapshot().own_perception.blind_until_tick
	await advance(5)
	expect(runtime.snapshot().own_perception.blind_until_tick == wave_blind_until, "one passing wave cannot refresh blindness every frame")
	# New runtime clears blindness/recognition; actual fire generates narrow audio.
	yaw = -PI / 2.0
	fresh()
	enemy.global_position = Vector3(-4, 0, 3)
	var weapon: Node3D = player.get_node("Camera3D/Weapon")
	weapon.fire(player.global_position + Vector3.UP * 1.6, Vector3.UP, false, player)
	await advance(24)
	expect(count_since("heard", 0, "gunshot") == 1, "actual shared weapon fire becomes delayed sound")
	cutoff = next_tick()
	scene.utility.throw_flash(player.global_position + Vector3.UP, Vector3.ZERO).freeze = true
	await advance(24)
	expect(count_since("heard", cutoff, "utility") == 1, "actual nearby utility deployment becomes delayed coarse audio")
	var audio_plain: bool = true
	for item in deliveries:
		if item.observation.source == "heard":
			audio_plain = audio_plain and Data.keys_exact(item.observation.content, ["type", "sound_kind", "distance_class"])
	expect(audio_plain, "heard sound contains no source identity or exact position")
	# Move the actual shared actor using its physics, then distinguish run/walk/crouch.
	enemy.global_position = Vector3(1, 0, 11.5)
	enemy.velocity = Vector3.ZERO
	enemy.set_move_dir(Vector3.RIGHT)
	cutoff = next_tick()
	await advance(25, true)
	expect(count_since("heard", cutoff, "footstep_run") > 0, "actual grounded running creates audible footsteps")
	for mode in [1, 2]:
		enemy.move_mode = mode
		enemy.set_move_dir(Vector3.LEFT)
		cutoff = next_tick()
		await advance(25, true)
		expect(count_since("heard", cutoff, "footstep_run") == 0, "shared walk/crouch stays quiet mode=" + str(mode))
	enemy.move_mode = 0
	enemy.velocity = Vector3.ZERO
	enemy.set_move_dir(Vector3.ZERO)
	enemy.global_position += Vector3(1, 0, 0)
	cutoff = next_tick()
	await advance(24)
	expect(count_since("heard", cutoff, "footstep_run") == 0, "stationary-velocity fixture teleport cannot become running audio")
	# Path-distance hearing: across corridor front + hall walls, Euclidean
	# distance is short but the actual navigable route exceeds utility radius.
	bot.global_position = Vector3(-4.5, 0, 11.5)
	var source_at := Vector3(-4.5, 0, -1)
	var path: PackedVector3Array = scene.builder.query_path(bot.global_position, source_at)
	var distance: float = 0.0
	for i in range(1, path.size()):
		distance += path[i - 1].distance_to(path[i])
	expect(bot.global_position.distance_to(source_at) < 15 and distance > 15, "hearing fixture separates Euclidean radius from actual navigation distance")
	cutoff = next_tick()
	scene.utility.throw_flash(source_at, Vector3.ZERO).freeze = true
	await advance(24)
	expect(count_since("heard", cutoff, "utility") == 0, "actual utility deployment outside path radius is inaudible through nearby wall")
	bot.global_position = Vector3(50, 0, 50)
	cutoff = next_tick()
	scene.utility.throw_flash(player.global_position, Vector3.ZERO).freeze = true
	await advance(24)
	expect(count_since("heard", cutoff) == 0, "off-navigation listener never hears via distant snapped anchor")
	expect("listener_off_navigation_hearing_suppressed" in decisions[-1].errors, "sensor diagnostics survive in decision telemetry")
	runtime.get("_sensing").sample(next_tick())
	await advance(1)
	expect("non_monotonic_scene_sample" in decisions[-1].errors, "failed sensor sample retains its exact error in decision telemetry")
	await verify_natural_smoke()
	await verify_aim_delivery()
	await verify_aim_reacquisition_order()
	await verify_player_entry()
	# Fresh equal-seed trials perturb genuinely hidden live truth and compare
	# newly generated contexts AND fallback decisions, not one frozen dictionary.
	bot.global_position = Vector3(-2, 0, 11.5)
	enemy.global_position = Vector3(-4, 0, 3)
	yaw = 0.0
	fresh()
	await advance(65)
	var baseline_contexts: Array = contexts.duplicate(true)
	var baseline_decisions: Array = decisions.duplicate(true)
	expect(count_since("seen", 0) == 0, "perturbation baseline opponent is actually unseen")
	enemy.global_position = Vector3(-4, 0, 2)
	fresh()
	await advance(65)
	expect(count_since("seen", 0) == 0, "perturbed opponent remains behind current-map geometry")
	expect(contexts == baseline_contexts and decisions == baseline_decisions, "unseen live opponent perturbation leaves newly generated policy inputs and fallback decisions identical")
	# Delivery provenance and context copy mutation cannot contaminate the inbox.
	var legal: bool = true
	for item in deliveries:
		legal = legal and item.observation.available_tick <= item.tick
	for context in baseline_contexts:
		for o in context.observations:
			legal = legal and o.available_tick <= context.tick
	expect(legal, "all emitted observations/contexts honor availability")
	expect(Data.valid(contexts) and Data.valid(decisions), "new policy inputs and telemetry are recursively plain copied data")
	# Dispose the fixture adapter before exercising the actual inherited reset.
	enemy.global_position = Vector3(2, 0, 11.5)
	yaw = -PI / 2.0
	await advance(4)
	expect(runtime.snapshot().observations.is_empty(), "old round has newly sampled sight pending behind delay at reset")
	var signal_count: int = scene.utility.get_signal_connection_list("deployed").size()
	var shot_count: int = weapon.get_signal_connection_list("fired").size()
	runtime.free()
	expect(scene.utility.get_signal_connection_list("deployed").size() == signal_count - 1, "disposing runtime disconnects its utility callback")
	expect(weapon.get_signal_connection_list("fired").size() == shot_count - 1, "disposing runtime disconnects its weapon callback")
	scene._restart()
	while scene.get("_restart_pending"):
		await get_tree().physics_frame
		await get_tree().process_frame
	expect(scene.runtime.snapshot().observations.is_empty() and scene.runtime.snapshot().own_perception.blind_until_tick == 0, "inherited reset clears pending evidence and blindness")
	expect(scene.utility.get_signal_connection_list("deployed").size() == signal_count, "reset attaches exactly one replacement utility listener")
	expect(weapon.get_signal_connection_list("fired").size() == shot_count, "reset attaches exactly one replacement weapon listener")
	while scene.runtime.current_tick() < 24:
		await get_tree().physics_frame
	expect(scene.runtime.snapshot().observations.is_empty(), "old pending sighting never arrives in the replacement round")
	# Let effects expire/reset coroutines finish before releasing the tree.
	await get_tree().process_frame
	print("PERSON2_SCENE_PERCEPTION_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	get_tree().quit(1 if failed else 0)
