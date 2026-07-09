extends VelocityComponent

var input_direction: Vector2

func move(direction: Vector2, _speed = speed):
	body.velocity = direction.normalized() * _speed

func attack_move(direction: Vector2):
	body.velocity = direction * (speed * 3) # faster for a burst
	if direction == Vector2.ZERO:
		body.velocity = get_direction_vector() * (speed * .5) # faster for a burst but if not input
	await get_tree().create_timer(0.1).timeout
	body.velocity = Vector2.ZERO

func dash(direction: Vector2):
	body.velocity = direction * (speed * 20)
	if body.velocity == Vector2.ZERO:
		body.velocity = get_direction_vector() * (speed * 5)
	await get_tree().create_timer(0.1).timeout
	body.velocity = Vector2.ZERO

func stop_move():
	body.velocity = Vector2.ZERO
