extends VelocityComponent

@export var input_component: InputComponent
var input_direction: Vector2

var is_boosting: bool = false
var is_dashing: bool = false

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	var input_dir = input_component.get_input_direction()

	# Update internal direction states
	last_direction = current_direction
	if input_dir.length() > 0:
		current_direction = get_direction_name(input_dir, current_direction)
	else:
		pass
	body.move_and_slide()

func move(direction: Vector2, _speed = speed):
	body.velocity = direction.normalized() * _speed

func attack_move(direction: Vector2):
	if is_boosting:
		return
	is_boosting = true
	body.velocity = direction.normalized() * (speed * 3)
	await get_tree().create_timer(0.1, true, false, true).timeout
	stop_move()
	is_boosting = false

func dash(direction: Vector2):
	if is_dashing:
		return
	is_dashing = true
	body.velocity = direction.normalized() * (speed * 5)
	if body.velocity == Vector2.ZERO:
		body.velocity = get_direction_vector() * (speed * 5)
	await get_tree().create_timer(0.1, true, false, true).timeout
	body.velocity = Vector2.ZERO
	is_dashing = false
