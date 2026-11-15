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

func fresh() -> void:
	if is_instance_valid(scene.runtime):
		scene.runtime.free()
	var settings: Dictionary = scene.get("_scenario")
	runtime = Runtime.new()
	scene.add_child(runtime)
	scene.runtime = runtime
	runtime.configure("ally", bot, scene.builder, Belief.new("ally", settings.planner.regions, ["enemy"]),
		settings.planner, settings.motion_markers, settings.entries, 900)
	runtime.attach_perception(SceneSensor.new("ally", bot, scene.builder, scene.utility,
		{"enemy": enemy}, settings.perception, int(settings.perception_seed), 900, player))
	runtime.set_physics_process(false)
	runtime.observation_delivered.connect(func(o: Dictionary, tick: int): deliveries.append({"observation": o, "tick": tick}))
	runtime.policy_context_ready.connect(func(c: Dictionary): contexts.append(c))
	runtime.decision_recorded.connect(func(d: Dictionary): decisions.append(d))
	deliveries.clear()
	contexts.clear()
	decisions.clear()

func advance(count: int, move_enemy: bool = false) -> void:
	for i in count:
		if move_enemy:
			enemy._physics_process(1.0 / 60.0)
		await get_tree().physics_frame
		await get_tree().process_frame
		bot.rotation.y = yaw
		runtime._physics_process(1.0 / 60.0)

func count_since(source: String, cutoff: int, kind: String = "") -> int:
	var total: int = 0
	for item in deliveries:
		var o: Dictionary = item.observation
		if o.source == source and o.event_tick >= cutoff and (kind.is_empty() or o.content.get("sound_kind") == kind):
			total += 1
	return total

func next_tick() -> int:
	return runtime.current_tick() + 1

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
	var first: Dictionary = deliveries[0].observation
	expect(first.content == {"type": "enemy_seen", "enemy_id": "enemy", "region_id": "corridor"}, "sighting contains agreed region content only")
	expect(deliveries[0].tick == first.available_tick and first.available_tick - first.event_tick >= 12 and first.available_tick - first.event_tick <= 18, "seeded sight delivery honors actual availability tick")
	await advance(5)
	var visible_context: Dictionary = contexts[-1].duplicate(true)
	expect(first.id in visible_context.belief.evidence_ids, "due live sighting reaches actual Person 3 belief evidence")
	var candidate: Dictionary = {"context_id": visible_context.context_id, "decision_id": "sight-backed", "bot_id": "ally",
		"goal": "hold", "target_id": "home", "watch_region_id": "entry", "evidence_ids": [first.id]}
	expect(runtime.submit_intent(candidate).ok, "model intent may cite sighting actually delivered in captured context")
	candidate.decision_id = "invented-evidence"
	candidate.evidence_ids = ["not-delivered"]
	expect(not runtime.submit_intent(candidate).ok, "model intent cannot cite missing sensory evidence")
	contexts[-1].observations[0].content.region_id = "tampered"
	expect(runtime.snapshot().observations[0].content.region_id == "corridor", "mutating emitted context cannot change private sensory inbox")
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
	var wave: Node3D = scene.utility.throw_blind_wave(blocked_at, Vector3.FORWARD)
	# Drive this actual shared effect to its detonation position, avoiding a
	# travel-distance assumption. Its directional/range/duration method is real.
	wave.set_physics_process(false)
	wave.global_position = blocked_at
	wave.is_active = true
	bot.rotation.y = yaw
	var expected_duration: float = wave.blind_duration_for(bot.global_position + Vector3.UP * 1.6, Vector3.FORWARD, false) + 1.0
	var wave_tick: int = next_tick()
	await advance(1)
	expect(runtime.snapshot().own_perception.blind_until_tick == wave_tick + int(ceil(expected_duration * 60.0)), "explicit blind-wave registry applies through-wall duration plus shared extra second")
	wave.is_active = false
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
