extends Node

var attack_state: = 0
var can_attack: = true
var can_dash: = true
var can_block: = true

func lock_attack(duration: float) -> void:
	can_attack = false
	await get_tree().create_timer(duration).timeout
	can_attack = true

func reset_attack_state():
	attack_state = 0

func lock_dash(duration: float) -> void:
	can_dash = false
	await get_tree().create_timer(duration).timeout
	can_dash = true

#func lock_block()
