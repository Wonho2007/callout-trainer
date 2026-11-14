extends SceneTree
# A real Godot raycast -> delayed inbox -> real Person 3 beliefs -> Person 2 goal.
const Sensor = preload("res://perception/perception_sensor.gd")
const Probe = preload("res://tests/person2/physics_probe.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
const Belief = preload("res://belief/region_belief.gd")
const Data = preload("res://perception/plain_data.gd")
var checks: int = 0
var failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		printerr("FAIL: ", label)
		failed = true

func _run() -> void:
	var probe = Probe.new()
	root.add_child(probe)
	var body = StaticBody3D.new()
	body.collision_layer = 4
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(0.6, 2, 0.6)
	shape.shape = box
	body.add_child(shape)
	probe.add_child(body)
	body.position = Vector3(0, 1, -5)
	await physics_frame
	await physics_frame
	var settings: Dictionary = {"region_ids": ["entrance", "logs", "site"], "vision_mask": 23, "vision_range": 20.0, "fov_degrees": 90.0,
		"near_range": 8.0, "near_exposure_ticks": 1, "far_exposure_ticks": 2, "refresh_ticks": 6,
		"delay_min_ticks": 2, "delay_max_ticks": 2,
		"sound_radii": {"footstep_run": 11.0, "footstep_walk": 0.0, "footstep_crouch": 0.0, "gunshot": 40.0, "utility": 15.0, "defuse": 12.0},
		"hearing_near_distance": 3.0, "navigation_layers": 1, "navigation_snap_distance": 0.25}
	var sensor = Sensor.new("ally", settings, 7)
	var observer: Dictionary = {"eye": Vector3(0,1.5,0), "position": Vector3.ZERO, "forward": Vector3.FORWARD,
		"exclude_rids": [], "blind_until_tick": 0, "alive": true}
	var targets: Array = [{"enemy_id": "enemy", "region_id": "logs", "sample_points": [body.position], "collision_rids": [body.get_rid()]}]
	var sampled: Dictionary = await probe.sample(sensor, 0, observer, targets)
	expect(sampled.ok and sampled.observations.is_empty(), "recognition precedes sight event")
	sampled = await probe.sample(sensor, 1, observer, targets)
	expect(sampled.observations.size() == 1 and Data.valid(sampled), "actual physics produces plain-data sighting")
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	var executor = Executor.new("ally", {"entries": [], "flashes": [], "regions": settings.region_ids, "speakers": ["player"]}, schema)
	var beliefs = Belief.new("ally", settings.region_ids, ["enemy"])
	var configuration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://scenarios/synthetic_coverage.json")).planner
	var planner = Planner.new("ally", configuration)
	var physical: Dictionary = {"alive": true, "flash_count": 1, "reachable_target_ids": []}
	var own: Dictionary = {"alive": true, "marker_id": "home", "reachable_marker_ids": ["home", "logs_cover"],
		"role": "hold", "objective": "none"}
	expect(executor.enqueue(sampled.observations[0]).ok, "sighting queued without exposing world handles")
	executor.step(2, physical)
	expect(executor.inbox.available().is_empty(), "no sensor event reaches belief early")
	expect(planner.decide(2, beliefs.snapshot(), own, executor.inbox).decision.target_id == "home", "bot holds prior before reaction delay")
	executor.step(3, physical)
	var due: Array = executor.inbox.available()
	expect(due.size() == 1 and executor.inbox.evidence_available(due[0].id, 3), "delayed sighting becomes usable")
	expect(beliefs.apply(due[0], 3).ok, "real Person 3 module accepts actual sensor shape")
	var result: Dictionary = planner.decide(3, beliefs.snapshot(), own, executor.inbox)
	expect(result.ok and result.decision.target_id == "logs_cover", "physical sight changes actual knowledge-planner goal")
	expect(result.decision.evidence_ids == [due[0].id], "raycast-to-goal provenance remains intact")
	probe.queue_free()
	await process_frame
	print("PERSON2_SENSOR_INTEGRATION_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	quit(1 if failed else 0)
