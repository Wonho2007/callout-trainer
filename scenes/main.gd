extends Node3D
## Bootstrap scene (Person 1).
##
## Builds the synthetic test room from data, spawns the first-person player at
## the player spawn marker, and handles restart. This is the stage-1 "empty
## synthetic room" entry point; actors beyond the player and all gameplay are
## later increments.

const PlayerScene := preload("res://scenes/player/player.tscn")
const ActorScene := preload("res://actors/actor_base.tscn")
const SpikeScript := preload("res://world/spike.gd")
const GameEventsScript := preload("res://recording/game_events.gd")

@onready var builder = $SandboxBuilder
@onready var utility: UtilitySystem = $UtilitySystem

var _player: ActorBase
var _target: ActorBase
var _spike: Spike
var _events: GameEvents
var _round_state: String = "active"  # active | defused | detonated | player_down


func _ready() -> void:
	# Privileged event bus for Person 3's grader/recorder (not a policy input).
	_events = GameEventsScript.new()
	add_child(_events)
	utility.deployed.connect(func(ability_id, thrower_id, pos):
		_events.record(GameEvents.T_UTILITY, thrower_id, pos, {"ability": ability_id}))
	# The builder builds itself on _ready; ensure it is ready before spawning.
	await get_tree().process_frame
	_spawn_player()
	_spawn_target()
	_spawn_spike()
	_update_hud()
	# Confirm the navigation bake produced a usable path once it is ready.
	if not builder.navigation_is_ready:
		await builder.navigation_ready
	_verify_navigation()


func _process(_delta: float) -> void:
	_update_status()


func _physics_process(delta: float) -> void:
	# Hold-to-defuse: while alive, in range, and holding the defuse action.
	if _round_state != "active" or _spike == null or _player == null:
		return
	var holding := _player.is_alive and Input.is_action_pressed("defuse") \
			and _spike.in_range(_player.global_position)
	if holding:
		var was := _spike.defuse_progress
		_spike.defuse_step(_player.global_position, delta)
		if was == 0.0 and _spike.defuse_progress > 0.0:
			_events.record(GameEvents.T_DEFUSE_START, "player", _spike.global_position, {})
	else:
		if _spike.defuse_progress > 0.0:
			_events.record(GameEvents.T_DEFUSE_STOP, "player", _spike.global_position,
				{"progress": _spike.defuse_progress})
		_spike.stop_defuse()


func _verify_navigation() -> void:
	var from = builder.get_region_center("region_a")
	var to = builder.get_region_center("region_b")
	if from == null or to == null:
		push_warning("main: could not find region centers for nav check")
		return
	var path: PackedVector3Array = builder.query_path(from as Vector3, to as Vector3)
	if path.size() < 2:
		push_warning("main: navigation path region_a -> region_b is empty; navmesh may not have baked")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		_restart()


func _spawn_player() -> void:
	var spawn: Marker3D = builder.get_spawn("player")
	_player = PlayerScene.instantiate()
	add_child(_player)
	_player.died.connect(_on_player_died)
	# Give the player references it needs for utility (shared mechanics side).
	_player.utility = utility
	_player.flash_overlay = get_node_or_null("HUD/FlashOverlay")
	_player.blind_overlay = get_node_or_null("HUD/BlindOverlay")
	_player.smoke_overlay = get_node_or_null("HUD/SmokeOverlay")
	# Privileged event records for Person 3's grader (not a policy input path).
	_player.health.damaged.connect(func(amount, remaining):
		_events.record(GameEvents.T_DAMAGE, "player", _player.global_position,
			{"amount": amount, "remaining": remaining}))
	_player.died.connect(func():
		_events.record(GameEvents.T_DEATH, "player", _player.global_position, {}))
	var w := _player.get_node_or_null("Camera3D/Weapon")
	if w:
		w.fired.connect(func(from_pos, to_pos, hit):
			_events.record(GameEvents.T_SHOT_FIRED, "player", from_pos,
				{"to": [to_pos.x, to_pos.y, to_pos.z], "hit": hit}))
	if spawn:
		_player.teleport_to(spawn)
	else:
		push_warning("main: no player spawn marker found; placing at origin")
		_player.global_position = Vector3(0, 1, 0)


func _spawn_target() -> void:
	# A dummy target actor (Health, no AI) so the rifle has something to hit.
	# This is a Person 1 test stand-in, not a bot; Person 2 owns real bots.
	var spawn: Marker3D = builder.get_spawn("enemy")
	_target = ActorScene.instantiate()
	add_child(_target)
	if spawn:
		_target.teleport_to(spawn)
	else:
		_target.global_position = Vector3(7, 1, -7)
	_wire_minimap()


func _wire_minimap() -> void:
	var foes: Array = []
	if _target:
		foes.append(_target)
	# The scan orb tests against the same enemy list.
	if _player:
		_player.scan_targets = foes
	var mm := get_node_or_null("HUD/Minimap")
	if mm == null:
		return
	mm.builder = builder
	mm.player = _player
	mm.enemies = foes
	mm.utility = utility   # so the minimap can draw decaying recon marks
	mm.refresh()


func _spawn_spike() -> void:
	var pos = builder.get_spike_position()
	if pos == null:
		return
	_spike = SpikeScript.new()
	add_child(_spike)
	_spike.global_position = pos as Vector3
	_spike.defused.connect(_on_spike_defused)
	_spike.detonated.connect(_on_spike_detonated)


func _on_spike_defused() -> void:
	_round_state = "defused"
	if _events and _spike:
		_events.record(GameEvents.T_DEFUSE_DONE, "player", _spike.global_position, {})


func _on_spike_detonated() -> void:
	_round_state = "detonated"
	if _events and _spike:
		_events.record(GameEvents.T_DETONATED, "", _spike.global_position, {})


func _on_player_died() -> void:
	# The player's combatant state is dead, but input/comms stay available so the
	# player can still report (COMMUNICATION_COACHING). For this single-player
	# scaffold, the player dying ends the round (no teammates yet).
	if _round_state == "active":
		_round_state = "player_down"


func _restart() -> void:
	# Rebuild the room cleanly (no duplicated nodes) and reset the player/target.
	builder.build_from_file(builder.map_path)
	var pspawn: Marker3D = builder.get_spawn("player")
	if _player and pspawn:
		_player.teleport_to(pspawn)
	var espawn: Marker3D = builder.get_spawn("enemy")
	if _target and espawn:
		_target.teleport_to(espawn)
	if _spike:
		var pos = builder.get_spike_position()
		if pos != null:
			_spike.global_position = pos as Vector3
		_spike.reset()
	if _events:
		_events.clear()
	_round_state = "active"


func _update_hud() -> void:
	var hud := get_node_or_null("HUD/Hints")
	if hud:
		hud.text = "WASD | LMB fire | V dash | R reload | Q smoke | E flash | G wave | X molly | T scan | Hold C defuse | F restart | Esc mouse"


func _update_status() -> void:
	_update_round_label()
	_update_events_label()
	var label := get_node_or_null("HUD/Status")
	if label == null or _player == null:
		return
	var hp := _player.health.hp if _player.health else 0.0
	var state := "ALIVE" if _player.is_alive else "DEAD (can still look/report)"
	var ammo := ""
	var w := _player.get_node_or_null("Camera3D/Weapon")
	if w:
		ammo = "   Ammo: %d/%d" % [w.in_mag, w.reserve]
	var tgt := ""
	if _target and _target.health:
		var tstate := "" if _target.is_alive else " (down)"
		tgt = "   Target HP: %d%s" % [int(_target.health.hp), tstate]
	label.text = "HP: %d   %s%s%s" % [int(hp), state, ammo, tgt]


func _update_round_label() -> void:
	var label := get_node_or_null("HUD/Round")
	if label == null:
		return
	match _round_state:
		"defused":
			label.text = "SPIKE DEFUSED — round won.  Press R to restart."
		"detonated":
			label.text = "SPIKE DETONATED — round lost.  Press R to restart."
		"player_down":
			label.text = "YOU ARE DOWN — round lost.  Press R to restart."
		_:
			if _spike:
				var pct := int(_spike.defuse_progress * 100.0)
				var dz := ""
				if _player and _spike.in_range(_player.global_position):
					dz = "   [in defuse range — hold C]"
				label.text = "Spike: %4.1fs   Defuse: %d%%%s" % [_spike.time_left, pct, dz]
			else:
				label.text = ""


func _update_events_label() -> void:
	var label := get_node_or_null("HUD/Events")
	if label == null or _events == null:
		return
	var events_log := _events.get_log()
	var last := ""
	if events_log.size() > 0:
		last = "   last: %s" % events_log[events_log.size() - 1]["type"]
	label.text = "Events: %d%s" % [events_log.size(), last]
