class_name VelocityComponent extends Node

@export var speed: float = 100.00
@export var body: CharacterBody2D

var initial_direction: String = "down"
var current_direction: String = "down"
var last_direction: String = "down"

signal knockback_finished

func get_direction_name(input_vector: Vector2, previous_direction: String) -> String:
	var directions = []

	if input_vector.x < 0:
		directions.append("left")
	elif input_vector.x > 0:
		directions.append("right")

	if input_vector.y < 0:
		directions.append("up")
	elif input_vector.y > 0:
		directions.append("down")

	# If nothing pressed, return previous direction
	if directions.is_empty():
		return previous_direction

	# If only one direction, return it
	if directions.size() == 1:
		return directions[0]

	# If current direction is still pressed, keep it
	if directions.has(previous_direction):
		return previous_direction

	# Else, pick one randomly or by priority
	# Priority order: down > up > left > right
	for dir in ["down", "up", "left", "right"]:
		if directions.has(dir):
			return dir

	return directions[0]  # Fallback

func get_direction_vector():
	var directions_mapping: Dictionary = {
		"down" : Vector2.DOWN,
		"up" : Vector2.UP,
		"left" : Vector2.LEFT,
		"right" : Vector2.RIGHT
	}
	return directions_mapping.get(current_direction)
	
func knockback(power: float, source: Vector2, duration: float = .1) -> void:
	var knockback_direction = (body.global_position - source).normalized() 
	body.velocity = knockback_direction * power
	await get_tree().create_timer(duration).timeout
	knockback_finished.emit()
	stop_move()
	
func stop_move():
	body.velocity = Vector2.ZERO
