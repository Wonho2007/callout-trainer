extends SceneTree
const Sensor = preload("res://perception/perception_sensor.gd")
const Inbox = preload("res://perception/observation_inbox.gd")
const Data = preload("res://perception/plain_data.gd")
const Probe = preload("res://tests/person2/physics_probe.gd")
var checks: int = 0
var failures: Array[String] = []
var probe: Node3D
var enemy: StaticBody3D
var wall: StaticBody3D
var smoke: Area3D
var nav_map: RID
var nav_region: RID

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	probe = Probe.new()
	root.add_child(probe)
	enemy = body(Vector3(0, 1, -5), Vector3(0.6, 2, 0.6), 4)
	wall = body(Vector3(0, 1.5, -2.5), Vector3(4, 3, 0.5), 1)
	smoke = Area3D.new()
	smoke.collision_layer = 16
	smoke.collision_mask = 0
	var shape = CollisionShape3D.new()
	var volume = SphereShape3D.new()
	volume.radius = 1.0
	shape.shape = volume
	smoke.add_child(shape)
	probe.add_child(smoke)
	smoke.position = Vector3(30, 1, 0)
	wall.position.x = 30
	await settle()
	await test_visible_and_delay()
	await test_wall_partial_and_target_hit()
	await test_fov_range_and_blind()
	await test_smoke_and_reacquisition()
	await test_hearing()
	await test_validation_and_replay()
	await test_edge_cases()
	await test_exposure_self_and_refresh()
	if nav_region.is_valid():
		NavigationServer3D.free_rid(nav_region)
	if nav_map.is_valid():
		NavigationServer3D.free_rid(nav_map)
	probe.queue_free()
	await process_frame
	if failures.is_empty():
		print("PERSON2_PERCEPTION_PASS checks=", checks)
		quit(0)
	else:
		for failure in failures:
			printerr(failure)
		quit(1)

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append("FAIL: " + label)

func cfg() -> Dictionary:
	return {"region_ids": ["logs", "site"], "vision_mask": 23, "vision_range": 20.0, "fov_degrees": 90.0,
		"near_range": 8.0, "near_exposure_ticks": 1, "far_exposure_ticks": 2, "refresh_ticks": 6,
		"delay_min_ticks": 2, "delay_max_ticks": 4,
		"sound_radii": {"footstep_run": 11.0, "footstep_walk": 0.0, "footstep_crouch": 0.0,
			"gunshot": 40.0, "utility": 15.0, "defuse": 12.0},
		"hearing_near_distance": 3.0, "navigation_layers": 1, "navigation_snap_distance": 0.25}

func observer() -> Dictionary:
	return {"eye": Vector3(0, 1.5, 0), "position": Vector3.ZERO, "forward": Vector3.FORWARD,
		"exclude_rids": [], "blind_until_tick": 0, "alive": true}

func target(region: String = "logs") -> Dictionary:
	return {"enemy_id": "enemy", "region_id": region, "sample_points": [
		enemy.position + Vector3(0, 0.7, 0), enemy.position,
		enemy.position - Vector3(0, 0.7, 0)], "collision_rids": [enemy.get_rid()]}

func body(position: Vector3, size: Vector3, layer: int) -> StaticBody3D:
	var result = StaticBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	shape.shape = box
	result.add_child(shape)
	result.collision_layer = layer
	result.collision_mask = 0
	probe.add_child(result)
	result.position = position
	return result

func settle() -> void:
	await physics_frame
	await physics_frame

func test_visible_and_delay() -> void:
	var sensor = Sensor.new("ally", cfg(), 17)
	var output: Dictionary = await probe.sample(sensor, 0, observer(), [target()])
	expect(output.ok and output.observations.is_empty(), "minimum exposure before sighting")
	output = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.size() == 1, "real collider becomes a sighting")
	var seen: Dictionary = output.observations[0]
	expect(seen.source == "seen" and seen.content == {"type": "enemy_seen", "enemy_id": "enemy", "region_id": "logs"}, "seen payload matches Person 3")
	expect(seen.event_tick == 1 and seen.available_tick >= 3 and seen.available_tick <= 5, "seeded reaction delay")
	expect(Data.valid(output), "sensor output contains only plain copied values")
	var inbox = Inbox.new("ally")
	expect(inbox.enqueue(seen).ok, "sensor integrates with private inbox")
	expect(inbox.release(int(seen.available_tick) - 1).is_empty(), "policy cannot see sighting early")
	expect(inbox.release(int(seen.available_tick)).size() == 1, "sighting delivered on availability boundary")
	expect(inbox.evidence_available(seen.id, int(seen.available_tick)), "sighting has usable evidence")
	output = await probe.sample(sensor, 2, observer(), [target()])
	expect(output.observations.is_empty(), "continuous sight does not spam every tick")
	output = await probe.sample(sensor, 3, observer(), [target("site")])
	expect(output.observations.size() == 1 and output.observations[0].content.region_id == "site", "region change updates last seen information")
	expect(not JSON.stringify(output).contains("position") and not JSON.stringify(output).contains("collision_rids"), "no hidden coordinates or collider handles emitted")

func test_wall_partial_and_target_hit() -> void:
	wall.position = Vector3(0, 1.5, -2.5)
	await settle()
	var sensor = Sensor.new("ally", cfg(), 17)
	await probe.sample(sensor, 0, observer(), [target()])
	var output: Dictionary = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.is_empty(), "solid world wall blocks target")
	# Low cover hides feet/torso while leaving the head sample visible.
	var low_shape: BoxShape3D = wall.get_child(0).shape
	low_shape.size = Vector3(4, 1.45, 0.5)
	wall.position.y = 0.725
	await settle()
	await probe.sample(sensor, 2, observer(), [target()])
	output = await probe.sample(sensor, 3, observer(), [target()])
	expect(output.observations.size() == 1, "partial cover does not hide an exposed head")
	expect(not JSON.stringify(output).contains("region_clear"), "point samples never assert whole-region clearance")
	low_shape.size = Vector3(4, 3, 0.5)
	wall.position = Vector3(30, 1.5, -2.5)
	await settle()
	var forged = target()
	forged.collision_rids = [wall.get_rid()]
	sensor = Sensor.new("ally", cfg(), 17)
	await probe.sample(sensor, 0, observer(), [forged])
	output = await probe.sample(sensor, 1, observer(), [forged])
	expect(output.observations.is_empty(), "clear ray must actually hit the registered target collider")

func test_fov_range_and_blind() -> void:
	var sensor = Sensor.new("ally", cfg(), 17)
	var state = observer()
	state.forward = Vector3.BACK
	await probe.sample(sensor, 0, state, [target()])
	var output: Dictionary = await probe.sample(sensor, 1, state, [target()])
	expect(output.observations.is_empty(), "target behind observer is outside FOV")
	var settings = cfg()
	settings.vision_range = 2.0
	sensor = Sensor.new("ally", settings, 17)
	await probe.sample(sensor, 0, observer(), [target()])
	output = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.is_empty(), "vision range enforced")
	sensor = Sensor.new("ally", cfg(), 17)
	state = observer()
	state.blind_until_tick = 2
	await probe.sample(sensor, 0, state, [target()])
	output = await probe.sample(sensor, 1, state, [target()])
	expect(output.observations.is_empty(), "flash suppresses visual sensing")
	output = await probe.sample(sensor, 2, state, [target()])
	expect(output.observations.is_empty(), "vision recognition restarts when flash ends")
	output = await probe.sample(sensor, 3, state, [target()])
	expect(output.observations.size() == 1, "vision recovers after blind status and exposure")
	state.alive = false
	output = await probe.sample(sensor, 4, state, [target()])
	expect(output.observations.is_empty(), "dead observer emits no sightings")

func test_smoke_and_reacquisition() -> void:
	smoke.position = Vector3(0, 1.5, -2.5)
	await settle()
	var sensor = Sensor.new("ally", cfg(), 17)
	await probe.sample(sensor, 0, observer(), [target()])
	var output: Dictionary = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.is_empty(), "smoke Area3D blocks rays")
	smoke.position = observer().eye
	await settle()
	await probe.sample(sensor, 2, observer(), [target()])
	output = await probe.sample(sensor, 3, observer(), [target()])
	expect(output.observations.is_empty(), "observer inside smoke cannot see through it")
	smoke.position = Vector3(30, 1, 0)
	await settle()
	await probe.sample(sensor, 4, observer(), [target()])
	output = await probe.sample(sensor, 5, observer(), [target()])
	expect(output.observations.size() == 1, "sighting after smoke clears")
	# A missing sampling interval cannot be assumed continuously visible.
	output = await probe.sample(sensor, 8, observer(), [target()])
	expect(output.observations.is_empty(), "skipped sensor ticks reset recognition")
	output = await probe.sample(sensor, 9, observer(), [target()])
	expect(output.observations.size() == 1, "reacquisition yields new evidence")

func sound(id: String, tick: int, kind: String, position: Vector3) -> Dictionary:
	return {"id": id, "event_tick": tick, "kind": kind, "position": position}

func build_navigation() -> void:
	nav_map = NavigationServer3D.map_create()
	NavigationServer3D.map_set_active(nav_map, true)
	var mesh = NavigationMesh.new()
	mesh.vertices = PackedVector3Array([Vector3(0,0,0), Vector3(10,0,0), Vector3(10,0,2),
		Vector3(2,0,2), Vector3(2,0,10), Vector3(0,0,10)])
	mesh.add_polygon(PackedInt32Array([0,3,2,1]))
	mesh.add_polygon(PackedInt32Array([0,5,4,3]))
	nav_region = NavigationServer3D.region_create()
	NavigationServer3D.region_set_navigation_mesh(nav_region, mesh)
	NavigationServer3D.region_set_map(nav_region, nav_map)
	await settle()
	NavigationServer3D.map_force_update(nav_map)

func test_hearing() -> void:
	await build_navigation()
	var state = observer()
	state.position = Vector3(1, 0, 8)
	state.eye = Vector3(1, 1.5, 8)
	state.blind_until_tick = 100
	var sensor = Sensor.new("ally", cfg(), 17)
	var output: Dictionary = await probe.sample(sensor, 0, state, [], [sound("near", 0, "footstep_run", Vector3(1,0,7))], nav_map)
	expect(output.ok and output.observations.size() == 1, "near sound heard even while flashed")
	var heard: Dictionary = output.observations[0]
	expect(heard.source == "heard" and heard.content.distance_class == "near", "coarse hearing observation")
	expect(Data.valid(heard) and not heard.content.has("enemy_id") and not heard.content.has("position") and not heard.content.has("region_id"), "sound reveals no hidden identity or exact location")
	output = await probe.sample(sensor, 1, state, [], [sound("corner", 1, "footstep_run", Vector3(8,0,1))], nav_map)
	expect(output.observations.is_empty(), "NavMesh path distance, not short straight-line distance, attenuates hearing")
	output = await probe.sample(sensor, 2, state, [], [sound("loud", 2, "gunshot", Vector3(8,0,1))], nav_map)
	expect(output.observations.size() == 1 and output.observations[0].content.distance_class == "far", "louder action heard around corner")
	output = await probe.sample(sensor, 3, state, [], [sound("quiet", 3, "footstep_walk", Vector3(1,0,7)),
		sound("crouch", 3, "footstep_crouch", Vector3(1,0,7))], nav_map)
	expect(output.observations.is_empty(), "walk/crouch quiet in this model")
	output = await probe.sample(sensor, 4, state, [], [sound("off_mesh", 4, "gunshot", Vector3(30,0,30))], nav_map)
	expect(output.observations.is_empty(), "off-mesh sound is not projected into a false reachable location")
	output = await probe.sample(sensor, 5, state, [], [sound("no_map", 5, "gunshot", Vector3(1,0,7))])
	expect(not output.ok and output.errors == ["navigation_not_ready"], "hearing never silently falls back to Euclidean range")

func test_validation_and_replay() -> void:
	var a = Sensor.new("ally", cfg(), 42)
	var b = Sensor.new("ally", cfg(), 42)
	for tick in range(9):
		var first: Dictionary = await probe.sample(a, tick, observer(), [target()])
		var second: Dictionary = await probe.sample(b, tick, observer(), [target()])
		expect(first == second, "fixed seed and inputs reproduce observations")
	var state = observer()
	state.forward = Vector3.ZERO
	var sensor = Sensor.new("ally", cfg(), 17)
	var output: Dictionary = await probe.sample(sensor, 0, state, [target()])
	expect(not output.ok, "invalid observer rejected")
	var malformed = target()
	malformed.region_id = "unknown_region"
	output = await probe.sample(sensor, 0, observer(), [malformed])
	expect(not output.ok, "unknown target region rejected")
	output = await probe.sample(sensor, 0, observer(), [target(), target()])
	expect(not output.ok, "duplicate target identities rejected atomically")
	output = await probe.sample(sensor, 0, observer(), [target()])
	expect(output.ok, "invalid calls did not advance sensor clock")
	output = await probe.sample(sensor, 0, observer(), [target()])
	expect(not output.ok and output.errors == ["non_monotonic_tick"], "same tick cannot sense twice")
	var invalid = cfg()
	invalid.delay_min_ticks = 0
	output = await probe.sample(Sensor.new("ally", invalid, 17), 0, observer(), [])
	expect(not output.ok, "zero reaction delay configuration rejected")
	var copies = cfg()
	sensor = Sensor.new("ally", copies, 17)
	copies.region_ids.clear()
	await probe.sample(sensor, 0, observer(), [target()])
	output = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.ok and output.observations.size() == 1, "sensor configuration copied")

func test_edge_cases() -> void:
	var state = observer()
	state.position = Vector3(1, 0, 8)
	state.eye = Vector3(1, 1.5, 8)
	var sensor = Sensor.new("ally", cfg(), 7)
	var output: Dictionary = await probe.sample(sensor, 0, state, [], [sound("quiet_no_nav", 0, "footstep_walk", Vector3(1,0,7))])
	expect(output.ok and output.observations.is_empty(), "quiet event needs no NavMesh query")
	state.alive = false
	output = await probe.sample(sensor, 1, state, [], [sound("dead", 1, "gunshot", Vector3(1,0,7))])
	expect(output.ok and output.observations.is_empty(), "dead observer cannot hear")
	state.alive = true
	sensor = Sensor.new("ally", cfg(), 7)
	await probe.sample(sensor, 0, state, [], [sound("unique", 0, "footstep_run", Vector3(1,0,7))], nav_map)
	output = await probe.sample(sensor, 1, state, [], [sound("unique", 1, "footstep_run", Vector3(1,0,7))], nav_map)
	expect(not output.ok and output.errors == ["invalid_sounds"], "sound ID cannot be reused to replay an event")
	output = await probe.sample(sensor, 1, state, [], [sound("late", 0, "gunshot", Vector3(1,0,7))], nav_map)
	expect(not output.ok, "old sound is not evaluated from the listener's new position")
	output = await probe.sample(sensor, 1, state, [], [sound("new", 1, "gunshot", Vector3(1,0,7))], nav_map)
	expect(output.ok and output.observations.size() == 1, "invalid batches do not consume clock or sound state")
	var unsynchronized = NavigationServer3D.map_create()
	output = await probe.sample(sensor, 2, state, [], [sound("unsynced", 2, "gunshot", Vector3(1,0,7))], unsynchronized)
	expect(not output.ok and output.errors == ["navigation_not_ready"], "unsynchronized map rejected")
	NavigationServer3D.free_rid(unsynchronized)
	var island = NavigationMesh.new()
	island.vertices = PackedVector3Array([Vector3(20,0,20), Vector3(24,0,20), Vector3(24,0,24), Vector3(20,0,24)])
	island.add_polygon(PackedInt32Array([0,3,2,1]))
	var island_region = NavigationServer3D.region_create()
	NavigationServer3D.region_set_navigation_mesh(island_region, island)
	NavigationServer3D.region_set_map(island_region, nav_map)
	await settle()
	NavigationServer3D.map_force_update(nav_map)
	output = await probe.sample(sensor, 2, state, [], [sound("island", 2, "gunshot", Vector3(21,0,21))], nav_map)
	expect(output.ok and output.observations.is_empty(), "disconnected on-mesh endpoints do not create a false hearing path")
	NavigationServer3D.free_rid(island_region)
	await settle()
	# Invalid privileged data must fail before it mutates visual recognition.
	for key in ["eye", "position", "forward"]:
		for wrong in [null, true, 1, "position", Vector3(INF, 0, 0)]:
			var bad = observer()
			bad[key] = wrong
			output = await probe.sample(Sensor.new("ally", cfg(), 7), 0, bad, [target()])
			expect(not output.ok, "malformed observer vector rejected: " + key)
	var bad_target = target()
	bad_target.enemy_id = 1
	output = await probe.sample(Sensor.new("ally", cfg(), 7), 0, observer(), [bad_target])
	expect(not output.ok, "malformed enemy identity rejected without Variant error")
	bad_target = target()
	bad_target.collision_rids = [RID()]
	output = await probe.sample(Sensor.new("ally", cfg(), 7), 0, observer(), [bad_target])
	expect(not output.ok, "empty collider handle rejected")
	var self_excluding = observer()
	self_excluding.exclude_rids = [enemy.get_rid()]
	output = await probe.sample(Sensor.new("ally", cfg(), 7), 0, self_excluding, [target()])
	expect(not output.ok, "registered enemy cannot also be excluded as self")
	output = await probe.sample(Sensor.new("ally", cfg(), 7), 2147483647, observer(), [target()])
	expect(not output.ok and output.errors == ["invalid_tick"], "delay arithmetic remains within inbox tick domain")
	# Equal visible inputs, seed and order-independent descriptors yield equal
	# observations despite an unseen enemy changing position.
	var hidden = body(Vector3(0, 1, 5), Vector3(0.6, 2, 0.6), 4)
	await settle()
	var hidden_target: Dictionary = {"enemy_id": "hidden", "region_id": "site",
		"sample_points": [hidden.position], "collision_rids": [hidden.get_rid()]}
	var a = Sensor.new("ally", cfg(), 7)
	var b = Sensor.new("ally", cfg(), 7)
	var a0: Dictionary = await probe.sample(a, 0, observer(), [hidden_target, target()])
	hidden.position = Vector3(30, 1, 0)
	await settle()
	hidden_target.sample_points = [hidden.position]
	var b0: Dictionary = await probe.sample(b, 0, observer(), [target(), hidden_target])
	expect(a0 == b0, "unseen world change produces no extra observation")
	var a1: Dictionary = await probe.sample(a, 1, observer(), [hidden_target, target()])
	var b1: Dictionary = await probe.sample(b, 1, observer(), [target(), hidden_target])
	expect(a1 == b1 and a1.observations.size() == 1, "hidden targets and registry order do not perturb visible-event RNG")
	hidden.queue_free()
	await settle()

func test_exposure_self_and_refresh() -> void:
	enemy.position = Vector3(0, 1, -12)
	await settle()
	var sensor = Sensor.new("ally", cfg(), 5)
	var output: Dictionary = await probe.sample(sensor, 0, observer(), [target()])
	expect(output.observations.is_empty(), "far target starts recognition")
	output = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.is_empty(), "far exposure longer than near exposure")
	output = await probe.sample(sensor, 2, observer(), [target()])
	expect(output.observations.size() == 1, "far sighting after configured exposure")
	for tick in range(3, 8):
		output = await probe.sample(sensor, tick, observer(), [target()])
		expect(output.observations.is_empty(), "no refresh before interval")
	output = await probe.sample(sensor, 8, observer(), [target()])
	expect(output.observations.size() == 1, "continuous sight refreshes at interval")
	enemy.position = Vector3(0, 1, -5)
	var self_body = body(Vector3(0,1,0), Vector3(0.6,2,0.6), 2)
	await settle()
	sensor = Sensor.new("ally", cfg(), 5)
	await probe.sample(sensor, 0, observer(), [target()])
	output = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.is_empty(), "unexcluded own collider blocks from-inside ray")
	var state = observer()
	state.exclude_rids = [self_body.get_rid()]
	sensor = Sensor.new("ally", cfg(), 5)
	await probe.sample(sensor, 0, state, [target()])
	output = await probe.sample(sensor, 1, state, [target()])
	expect(output.observations.size() == 1, "only observer collider can be excluded for valid sight")
	self_body.queue_free()
	await settle()
	smoke.collision_layer = 8
	smoke.position = Vector3(0,1.5,-2.5)
	await settle()
	sensor = Sensor.new("ally", cfg(), 5)
	await probe.sample(sensor, 0, observer(), [target()])
	output = await probe.sample(sensor, 1, observer(), [target()])
	expect(output.observations.size() == 1, "callout-region areas are excluded from vision blocker mask")
	smoke.collision_layer = 16
	smoke.position = Vector3(30,1,0)
	await settle()
	state = observer()
	state.position = Vector3(1,0,8)
	state.eye = Vector3(1,1.5,8)
	sensor = Sensor.new("ally", cfg(), 5)
	output = await probe.sample(sensor, 0, state, [], [sound("coincident", 0, "gunshot", state.position)], nav_map)
	expect(output.ok and output.observations.size() == 1, "zero-distance valid sound is not discarded")
