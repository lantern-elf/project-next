extends State

var blocking_direction: Vector2
var attacker_position: Vector2 = Vector2.ZERO
var dot: float

func enter():
	blocking_direction = velocity_component.get_direction_vector()
	if health_component.last_knockback_source:
		attacker_position = health_component.last_knockback_source
	dot = blocking_direction.dot(attacker_position)

func update(_delta: float):
	if dot > .5:
		print("blocked")
	
	if not Input.is_action_pressed("block"):
		Transitioned.emit(self, "Idle")

func physics_update(_delta: float):
	velocity_component.move(input.get_input_direction())

func exit():
	pass
