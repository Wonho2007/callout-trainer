extends RefCounted
# Privileged physical adapter. Receives only authored utility beats, never
# dynamic opponent destinations. Projectile collision can spoil a throw.
const Orb = preload("res://utility/scan_orb.gd")
var _actor: Node3D
var _runtime: Node
var _utility: Node3D
var _markers: Dictionary
var _id: String

func _init(id: String, actor: Node3D, runtime: Node, utility: Node3D, markers: Dictionary) -> void:
	_id = id
	_actor = actor
	_runtime = runtime
	_utility = utility
	_markers = markers.duplicate(true)

func execute(beat: Dictionary) -> bool:
	if not _actor.is_alive or _actor.get_meta("bot_blinded", false) or not _markers.has(beat.region):
		return false
	var state: Dictionary = _runtime.snapshot()
	if state.combat.decision.get("action") == "engage" or not state.active_command.is_empty():
		return false
	var p: Array = _markers[beat.region].position
	var target := Vector3(p[0], p[1], p[2])
	if beat.action == "reference_smoke":
		# Region/side from the annotation; metric offsets remain authored.
		target.x -= 1.0
		return _utility.throw_smoke(target, _id) != null
	var origin: Vector3 = _actor.global_position + Vector3.UP * 1.6
	var flight: float = 1.5 if beat.action == "reference_grenade" else 0.8
	var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	var velocity: Vector3 = (target + Vector3.UP * 0.5 - origin) / flight + Vector3.UP * gravity * flight * 0.5
	if beat.action == "reference_grenade":
		return _utility.throw_molly(origin, velocity, _id) != null
	if beat.action == "reference_recon":
		# Enemy Eye adaptation: private scan, never the player's HUD/recon API.
		var orb: RigidBody3D = Orb.new()
		_utility.add_child(orb)
		orb.throw(origin, velocity, [])
		orb.scanned.connect(func(_contacts: Array):
			if is_instance_valid(_runtime) and _actor.is_alive:
				_runtime.scan_scenario_recon(orb.global_position))
		_utility.deployed.emit("scan_orb", _id, origin)
		return true
	return false
