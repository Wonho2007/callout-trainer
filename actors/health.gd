extends Node
class_name Health
## Reusable health component (Person 1, shared actor mechanics).
##
## A plain counter shared by the player and all bots. Health/armor values and
## per-body-part logic are placeholders (brief §6.3) — this stub tracks a single
## hit-point pool and emits signals on change and death. Weapons/damage sources
## are a later Person 1 increment; this just holds the state they will drive.

signal damaged(amount: float, remaining: float)
signal died

@export var max_hp: float = 100.0

var hp: float = 100.0
var is_dead: bool = false


func _ready() -> void:
	hp = max_hp


## Apply damage. Clamps at 0 and emits died once. Ignored if already dead.
func apply_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	damaged.emit(amount, hp)
	if hp <= 0.0:
		is_dead = true
		died.emit()


## Reset to full health (used on round restart).
func reset() -> void:
	hp = max_hp
	is_dead = false
