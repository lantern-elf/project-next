extends VelocityComponent

@export var input_component: InputComponent
var input_direction: Vector2

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var input_dir = input_component.get_input_direction()

	# Update internal direction states
	last_direction = current_direction
	if input_dir.length() > 0:
		current_direction = get_direction_name(input_dir, current_direction)
	else:
		pass
	body.move_and_slide() # Move body

func move(direction: Vector2, _speed = speed):
	body.velocity = direction.normalized() * _speed

func attack_move(direction: Vector2):
	body.velocity = direction * (speed * 1) # faster for a burst
	#if direction == Vector2.ZERO:
		#body.velocity = get_direction_vector() * (speed * .5) # faster for a burst but if not input
	await get_tree().create_timer(0.1).timeout
	stop_move()

func dash(direction: Vector2):
	body.velocity = direction * (speed * 5)
	if body.velocity == Vector2.ZERO:
		body.velocity = get_direction_vector() * (speed * 5)
	await get_tree().create_timer(0.1).timeout
	body.velocity = Vector2.ZERO
