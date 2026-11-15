extends SceneTree
const Controller = preload("res://bots/flash_controller.gd")
const Actor = preload("res://tests/person2/motion_actor.gd")
class Utility:
	extends Node3D
	var launches: int = 0
	var fail: bool = false
	var during_release: Callable
	func throw_flash(_origin: Vector3, _velocity: Vector3) -> Node3D:
		launches += 1
		if during_release.is_valid():
			during_release.call()
		if fail:
			return null
		var effect := Node3D.new()
		add_child(effect)
		return effect
var checks: int = 0
var failed: bool = false
func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed = true
		printerr("FAIL: ", label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var actor := Actor.new()
	var utility := Utility.new()
	root.add_child(actor)
	root.add_child(utility)
	var targets: Dictionary = {"entry_flash": {"stage_marker_id": "home", "velocity": [0, 2, -8]}}
	var markers: Dictionary = {"home": {"position": [0, 0, 0], "watch_points": {}}}
	var adapter = Controller.new(actor, utility, targets, markers, 1)
	var reentrant: Array = []
	utility.during_release = func(): reentrant.append(adapter.launch("one", "entry_flash"))
	expect(adapter.launch("one", "entry_flash").ok and utility.launches == 1, "one launch creates one physical effect")
	expect(adapter.remaining() == 0, "inventory reserved at physical release")
	expect(reentrant.size() == 1 and not reentrant[0].ok and utility.launches == 1, "synchronous reentrant callback cannot double-release")
	utility.during_release = Callable()
	expect(adapter.launch("one", "entry_flash").ok and utility.launches == 1, "repeated physical command ID returns cached success")
	expect(adapter.launch("two", "entry_flash").reason == "no_utility" and utility.launches == 1, "second command cannot spend depleted inventory")
	adapter = Controller.new(actor, utility, targets, markers, 1)
	utility.fail = true
	expect(adapter.launch("failed", "entry_flash").reason == "physical_launch_failed" and adapter.remaining() == 1, "failed shared spawn refunds reserved charge")
	var launches: int = utility.launches
	expect(not adapter.launch("failed", "entry_flash").ok and utility.launches == launches, "failed command cannot retry an ambiguous physical release")
	utility.fail = false
	actor.is_alive = false
	expect(adapter.launch("dead", "entry_flash").reason == "actor_dead" and adapter.remaining() == 1, "death prevents release without consuming inventory")
	actor.is_alive = true
	actor.position.x = 2
	expect(adapter.launch("away", "entry_flash").reason == "outside_authored_launch_position" and utility.launches == launches, "displaced actor cannot throw from an unauthored position")
	actor.position = Vector3.ZERO
	expect(adapter.launch("unknown", "enemy_location").reason == "unknown_flash_target", "arbitrary target does not become a throw coordinate")
	adapter = Controller.new(actor, null, targets, markers, 1)
	expect(adapter.launch("missing", "entry_flash").reason == "utility_adapter_unavailable", "missing shared mechanism fails honestly")
	targets.entry_flash.velocity = [0, NAN, -8]
	adapter = Controller.new(actor, utility, targets, markers, 1)
	expect(adapter.targets().is_empty() and adapter.remaining() == 0, "invalid authored velocity cannot expose feasible utility")
	actor.free()
	utility.free()
	print("PERSON2_FLASH_" + ("FAIL" if failed else "PASS"), " checks=", checks)
	quit(1 if failed else 0)
