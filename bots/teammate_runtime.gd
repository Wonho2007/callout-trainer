extends Node
# PRIVILEGED scene orchestration. This object never enters a policy/model input.
const Data = preload("res://perception/plain_data.gd")
const Executor = preload("res://bots/command_executor.gd")
const Planner = preload("res://bots/knowledge_planner.gd")
const Motion = preload("res://bots/motion_controller.gd")
const Gate = preload("res://bots/intent_gate.gd")
const FlashController = preload("res://bots/flash_controller.gd")
const VisibleFlashController = preload("res://bots/visible_flash_controller.gd")
const CombatPolicy = preload("res://bots/combat_policy.gd")
const CombatController = preload("res://bots/combat_controller.gd")
signal policy_context_ready(context: Dictionary)
signal decision_recorded(record: Dictionary)
signal comm_result(result: Dictionary)
signal observation_delivered(observation: Dictionary, delivery_tick: int)
var _actor: Node3D
var _nav: Node3D
var _belief: RefCounted
var _executor: RefCounted
var _planner: RefCounted
var _motion: RefCounted
var _gate: RefCounted
var _configuration: Dictionary
var _markers: Dictionary
var _entries: Dictionary
var _usable_ids: Dictionary = {}
var _bot_id: String
var _tick: int = -1
var _context_serial: int = 0
var _round_id: int = 0
var _delivery_serial: int = 0
var _status: Dictionary = {}
var _last_plan: Dictionary = {}
var _configured: bool = false
var _sensing: RefCounted
var _sensory_ids: Dictionary = {}
var _applied_senses: Dictionary = {}
var _flash: RefCounted
var _combat_policy: RefCounted
var _combat_adapter: RefCounted
var _combat_decision: Dictionary = {}
var _scenario_policy: RefCounted
var _player_goal: Dictionary = {}
var _position_orders: Dictionary = {}
var _last_position_serial: int = 0

func attach_scenario_policy(policy: RefCounted) -> void:
	_scenario_policy = policy

func configure(bot_id: String, actor: Node3D, navigation: Node3D, belief: RefCounted,
		configuration: Dictionary, markers: Dictionary, entries: Dictionary, round_id: int,
		utility: Node3D = null, flash_targets: Dictionary = {}, flash_charges: int = 0) -> void:
	_bot_id = bot_id
	_actor = actor
	_actor.died.connect(_on_actor_died)
	_nav = navigation
	_belief = belief
	_round_id = round_id
	_configuration = configuration.duplicate(true)
	_markers = markers.duplicate(true)
	_entries = entries.duplicate(true)
	var schema: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://schemas/comms_v1.schema.json"))
	var visible_flashes: bool = flash_targets.values().any(func(target: Variant): return target is Dictionary and target.has("aim_points"))
	_flash = VisibleFlashController.new(actor, utility, flash_targets, markers, flash_charges) if visible_flashes else FlashController.new(actor, utility, flash_targets, markers, flash_charges)
	var visibility_flashes: Array = _flash.targets().keys() if visible_flashes else []
	_executor = Executor.new(bot_id, {"entries": entries.keys(), "flashes": _flash.targets().keys(), "visibility_flashes": visibility_flashes, "regions": configuration.regions, "speakers": ["player"]}, schema, 600)
	_planner = Planner.new(bot_id, configuration)
	_motion = Motion.new(bot_id, actor, navigation, markers, entries)
	_motion.attach_flash(_flash)
	var affordances: Dictionary = {}
	for marker in markers:
		affordances[marker] = markers[marker].watch_points.keys()
	_gate = Gate.new(bot_id, affordances)
	_configured = true

func _on_actor_died() -> void:
	# Keep the record for round logic and sensor registries, remove its physical
	# presence immediately. The player never uses this bot runtime.
	_actor.hide()
	_actor.set_deferred("collision_layer", 0)
	_actor.set_deferred("collision_mask", 0)
	for child in _actor.get_children():
		if child is CollisionObject3D:
			child.set_deferred("collision_layer", 0)
			child.set_deferred("collision_mask", 0)
	_actor.set_physics_process(false)
	finish_round("actor_dead")

func enable_combat(utility: Node3D) -> bool:
	# Trusted scene opt-in only. configure() leaves combat disabled so sensory
	# and information fixtures remain independent and never acquire a rifle.
	if not _configured:
		return false
	if _combat_adapter != null:
		return true
	var rifle: Node3D = load("res://weapons/weapon.gd").new()
	rifle.name = "TeammateRifle"
	_actor.add_child(rifle)
	rifle.occluder = utility
	_combat_policy = CombatPolicy.new(_bot_id, 30)
	_combat_adapter = CombatController.new(_bot_id, _actor, rifle)
	_motion.attach_combat(_combat_adapter)
	return true

func attach_perception(adapter: RefCounted) -> void:
	if _sensing != null:
		_sensing.dispose()
	_sensing = adapter

func register_opponent(id: String, actor: CharacterBody3D) -> bool:
	return _sensing != null and _sensing.register_opponent(id, actor)

func _exit_tree() -> void:
	if _combat_adapter != null:
		_combat_adapter.dispose()
	if _sensing != null:
		_sensing.dispose()

# Person 3's trusted voice/interpreter host passes normalized comms.v1 here.
# Fixed radio delivery is an explicit synthetic fixture assumption, not local
# acoustic hearing or a production team-radio/range decision.
func submit_comm(message: Dictionary) -> Dictionary:
	if not _configured or not Data.valid(message) or not Data.integer(message.get("issued_tick")) or message.issued_tick > _tick + 1:
		return {"ok": false, "reason": "invalid_or_future_comm"}
	_delivery_serial += 1
	var event_tick: int = _tick + 1
	return _executor.enqueue({"id": _bot_id + ":round:" + str(_round_id) + ":comm:" + str(_delivery_serial),
		"bot_id": _bot_id, "event_tick": event_tick, "available_tick": event_tick + 18,
		"source": "told", "speaker_id": "player", "content": {"type": "comms", "message": message.duplicate(true)}})

func submit_intent(candidate: Dictionary) -> Dictionary:
	if not _configured:
		return {"ok": false, "reason": "not_ready"}
	return _gate.propose(candidate, _tick)

# Local positioning seam, separate from the shared swing/flash comms schema.
# Only static authored marker IDs enter; delivery uses the same radio delay.
func submit_position_order(target_id: String) -> Dictionary:
	if not _configured or _bot_id != "ally" or not _actor.is_alive:
		return {"ok": false, "reason": "not_ready"}
	if not target_id.is_empty() and (not _markers.has(target_id) or not _markers[target_id].watch_points.has(target_id)):
		return {"ok": false, "reason": "unknown_position"}
	var issued: int = _tick + 1
	# Supersede a pending swing/flash through its existing cancellation rules.
	var active_id: String = _executor.active_command_id()
	if not active_id.is_empty():
		submit_comm({"schema_version": "comms.v1", "message_id": "position-cancel:" + str(_delivery_serial + 1),
			"speaker_id": "player", "recipient_id": _bot_id, "issued_tick": issued,
			"expires_tick": issued + 600, "kind": "cancel", "payload": {"command_id": active_id}})
	_delivery_serial += 1
	var id: String = _bot_id + ":round:" + str(_round_id) + ":position:" + str(_delivery_serial)
	var answer: Dictionary = _executor.enqueue({"id": id, "bot_id": _bot_id,
		"event_tick": issued, "available_tick": issued + 18, "source": "told",
		"speaker_id": "player", "content": {"type": "player_position", "target_id": target_id}})
	if answer.ok:
		_position_orders[id] = _delivery_serial
	return answer

func _update_player_goal() -> void:
	for observation in _executor.inbox.available():
		if not _position_orders.has(observation.id) or _position_orders[observation.id] <= _last_position_serial:
			continue
		_last_position_serial = _position_orders[observation.id]
		var target: String = observation.content.target_id
		_player_goal = {} if target.is_empty() else {"target_id": target, "evidence_ids": [observation.id]}
		_promote(observation.id)
		if _scenario_policy != null and not _player_goal.is_empty():
			_scenario_policy.consider_player_plan(_player_goal)

func _player_position_plan(own: Dictionary) -> Dictionary:
	var target: String = _player_goal.target_id
	var reachable: bool = target in own.reachable_marker_ids
	return {"ok": true, "errors": [], "replanned": true, "decision": {
		"tick": _tick, "bot_id": _bot_id,
		"goal": ("hold" if own.marker_id == target else "reposition") if reachable else "stop",
		"target_id": target if reachable else null, "watch_region_id": target if reachable else null,
		"reason": "persistent_player_position" if reachable else "player_position_unreachable",
		"evidence_ids": _player_goal.evidence_ids.duplicate(), "score": 0.0}}

func current_tick() -> int:
	return _tick

func invalidate_model_goal() -> void:
	# A disconnected/timed-out local host immediately relinquishes model control.
	# The pure gate rejects this empty candidate and clears the current proposal.
	if _configured:
		_gate.propose({}, _tick)

func finish_round(reason: String) -> void:
	# Trusted bootstrap calls for public round completion, not hidden events.
	_configured = false
	_player_goal.clear()
	_actor.set_move_dir(Vector3.ZERO)
	_status = {"ok": true, "state": "stopped", "reason": reason}

func snapshot() -> Dictionary:
	return {"tick": _tick, "bot_id": _bot_id, "physical": _status.duplicate(true),
		"player_goal": _player_goal.duplicate(true),
		"plan": _last_plan.duplicate(true), "active_command": _executor.active_command_snapshot(),
		"observations": _policy_observations(), "flash_count": _flash.remaining(),
		"combat": {"enabled": _combat_adapter != null, "decision": _combat_decision.duplicate(true), "physical": _motion.combat_status()},
		"own_perception": _sensing.own_status() if _sensing != null else {}}

func scenario_snapshot() -> Dictionary:
	return _scenario_policy.snapshot() if _scenario_policy != null and _scenario_policy.has_method("snapshot") else {}

func set_scenario_tick(tick: int) -> void:
	if _scenario_policy != null and _scenario_policy.has_method("set_scenario_tick"):
		_scenario_policy.set_scenario_tick(tick)

func take_scenario_utility() -> Array:
	return _scenario_policy.take_utility() if _scenario_policy != null and _scenario_policy.has_method("take_utility") else []

func scan_scenario_recon(origin: Vector3) -> void:
	if _configured and _sensing != null:
		_sensing.scan_recon(origin)

func _own_state() -> Dictionary:
	var marker_id: String = ""
	var reachable: Array = []
	for id in _markers:
		var coordinates: Array = _markers[id].position
		var at := Vector3(coordinates[0], coordinates[1], coordinates[2])
		var path: PackedVector3Array = _nav.query_path(_actor.global_position, at)
		if not path.is_empty() and path[-1].distance_to(at) <= 0.75 and path[0].distance_to(_actor.global_position) <= 0.75:
			reachable.append(id)
		if _actor.global_position.distance_to(at) < 0.3:
			marker_id = id
	return {"alive": _actor.is_alive, "marker_id": marker_id, "reachable_marker_ids": reachable, "role": "hold", "objective": "none"}

func _physics_process(_delta: float) -> void:
	if not _configured:
		return
	if not _nav.navigation_is_ready:
		_actor.set_move_dir(Vector3.ZERO)
		_status = {"ok": true, "state": "stopped", "reason": "navigation_not_ready"}
		return
	_tick += 1
	var sensing_errors: Array = []
	if _sensing != null:
		var sensed: Dictionary = _sensing.sample(_tick)
		sensing_errors = sensed.errors.duplicate()
		if sensed.ok:
			for observation in sensed.observations:
				if _executor.enqueue(observation).ok:
					_sensory_ids[observation.id] = true
				else:
					sensing_errors.append("invalid_sensor_envelope")
	var own: Dictionary = _own_state()
	var reachable_entries: Array = []
	for id in _entries:
		var entry: Dictionary = _entries[id]
		var reachable: bool = entry.stage_marker_id in own.reachable_marker_ids
		for waypoint in entry.route_marker_ids:
			reachable = reachable and waypoint in own.reachable_marker_ids
		if reachable:
			reachable_entries.append(id)
	for id in _flash.targets():
		if (_flash.has_method("uses_visibility") and _flash.uses_visibility(id)) or _flash.targets()[id].stage_marker_id in own.reachable_marker_ids:
			reachable_entries.append(id)
	var output: Dictionary = _executor.step(_tick, {"alive": _actor.is_alive,
		"flash_count": _flash.remaining(), "reachable_target_ids": reachable_entries}, _motion.take_feedback())
	output.errors.append_array(sensing_errors)
	for report in output.reports:
		for observation in _executor.inbox.available():
			if observation.id in report.evidence_ids:
				var applied: Dictionary = _belief.apply(observation, _tick)
				if not applied.ok:
					output.errors.append("belief_rejected_accepted_report")
	for result in output.results:
		if result.status != "rejected":
			for id in result.evidence_ids:
				_promote(id)
		comm_result.emit(result.duplicate(true))
	# Only due envelopes created by our registered privileged sensor adapter
	# enter this path. Hearing is delivered/logged, but Person 3's current belief
	# handler does not consume it. No fabricated sound likelihood is applied.
	for observation in _executor.inbox.available():
		if not _sensory_ids.has(observation.id) or _applied_senses.has(observation.id):
			continue
		_applied_senses[observation.id] = true
		if observation.source == "seen" and observation.content.get("type") == "enemy_seen":
			if not _belief.apply(observation, _tick).ok:
				output.errors.append("belief_rejected_sighting")
				continue
		_promote(observation.id)
	var active: Dictionary = _executor.active_command_snapshot()
	_update_player_goal()
	var own_vision: Dictionary = _sensing.own_status() if _sensing != null else {}
	var blinded: bool = int(own_vision.get("blind_until_tick", _tick + 1)) > _tick
	_actor.set_meta("bot_blinded", blinded)
	if _combat_policy != null:
		own_vision["alive"] = own.alive
		_combat_decision = _combat_policy.decide(_tick, _policy_observations(), own_vision)
	var plan: Dictionary = _planner.decide(_tick, _belief.snapshot(), own, _executor.inbox, active)
	if _scenario_policy != null:
		if _scenario_policy.has_method("consider_player_plan"):
			_scenario_policy.consider_player_plan(active)
		if active.is_empty() and _player_goal.is_empty():
			var scenario_own: Dictionary = own.duplicate(true)
			scenario_own["hp"] = _actor.health.hp
			scenario_own["blinded"] = blinded
			scenario_own["engaged"] = _combat_decision.get("action") == "engage"
			var scenario_decision: Dictionary = _scenario_policy.decide(_tick, _policy_observations(), scenario_own)
			if not scenario_decision.is_empty():
				plan = {"ok": true, "errors": [], "replanned": true, "decision": scenario_decision}
	var model: Dictionary = _gate.decision(_tick, _executor.inbox)
	var policy: String = "scripted_fallback"
	if not _player_goal.is_empty() and active.is_empty() and own.alive:
		plan = _player_position_plan(own)
		policy = "persistent_player_position"
	elif not model.is_empty() and active.is_empty() and own.alive:
		plan = {"ok": true, "errors": [], "decision": model, "replanned": true}
		policy = "local_model"
	elif not active.is_empty():
		policy = "accepted_player_command"
	_last_plan = plan.duplicate(true)
	_status = _motion.step(_tick, plan, output, active, _executor.inbox, _combat_decision)
	decision_recorded.emit({"tick": _tick, "bot_id": _bot_id, "policy": policy,
		"plan": plan.duplicate(true), "physical": _status.duplicate(true), "model_record": _gate.active_record(),
		"combat": {"enabled": _combat_adapter != null, "decision": _combat_decision.duplicate(true), "physical": _motion.combat_status()},
		"errors": output.errors.duplicate(true)})
	# A slow, bounded copied context is available for Person 3's local model.
	# Person 3 must also log its real prompt/raw response; this record cannot
	# establish what an external model actually received on its own.
	if _tick % 30 == 0:
		_context_serial += 1
		var context: Dictionary = {"context_id": _bot_id + ":round:" + str(_round_id) + ":context:" + str(_context_serial),
			"bot_id": _bot_id, "tick": _tick, "expires_tick": _tick + 120,
			"observations": _policy_observations(), "belief": _belief.snapshot(),
			"own_state": own, "active_command": active}
		if _gate.remember(context):
			policy_context_ready.emit(context.duplicate(true))

func _policy_observations() -> Array:
	var usable: Array = []
	for observation in _executor.inbox.available():
		if _usable_ids.has(observation.id):
			usable.append(observation)
	return usable

func _promote(id: String) -> void:
	if _usable_ids.has(id):
		return
	for observation in _executor.inbox.available():
		if observation.id == id:
			_usable_ids[id] = true
			observation_delivered.emit(observation.duplicate(true), _tick)
			return
