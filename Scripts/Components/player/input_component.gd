extends Node
class_name InputComponent

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
	if attack_disabled:
		return false
	return Input.is_action_just_pressed("attack")

func dash() -> bool:
	return Input.is_action_just_pressed("dash")
