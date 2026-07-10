class_name VelocityComponent extends Node

@export var speed: float = 100.00
@export var body: CharacterBody2D

var initial_direction: String = "down"
var current_direction: String = "down"
var last_direction: String = "down"

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
	@warning_ignore("unreachable_code")
	print(directions_mapping)

func knockback(direction: Vector2):
	body.velocity = -direction * 5
