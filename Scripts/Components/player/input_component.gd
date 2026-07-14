extends Node
class_name InputComponent

"""
Component that handles all player input (keyboard/gamepad):
movement direction, attack button, and dash button.
Other components (player state, etc.) simply call functions here
without needing to know the details of Godot's input mapping directly.
"""

signal direction_changes

var last_direction := Vector2.ZERO
var direction_changed := false
var attack_disabled := false

func _process(_delta: float) -> void:
	var current_direction = get_input_direction()
	if current_direction != last_direction:
		last_direction = current_direction
		direction_changed = true
		emit_signal("direction_changes")

func get_input_direction() -> Vector2:
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func attack() -> bool:
	return Input.is_action_just_pressed("attack")

func dash() -> bool:
	return Input.is_action_just_pressed("dash")

func block() -> bool:
	return Input.is_action_pressed("block")
