extends VelocityComponent

@export var input_component: InputComponent
var input_direction: Vector2
var _touched_pushables: Array = [] 
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
	_handle_push(delta, input_dir)

func _handle_push(delta: float, input_dir: Vector2) -> void:
	var currently_touched = [] # Gathering all touched pushable object
	var is_moving = input_dir.length() > 0  # Detect player's movement base on input
	for i in body.get_slide_collision_count(): # Detect all object that collided with player's body
		var collision = body.get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is CharacterBody2D and collider.is_in_group("Pushable"):
			currently_touched.append(collider)

			if is_moving:
				var push_dir = -collision.get_normal().round()
				collider.touch(push_dir, delta)
			else:
				collider.release()  

	for collider in _touched_pushables:
		if collider not in currently_touched and is_instance_valid(collider):
			collider.release()

	_touched_pushables = currently_touched

func move(direction: Vector2, _speed = speed):
	body.velocity = direction.normalized() * _speed
	update_facing_direction()
	moved.emit()

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

func bounce(source: Vector2):
	body.velocity = ((body.global_position - source).normalized() * 100)
	pass
