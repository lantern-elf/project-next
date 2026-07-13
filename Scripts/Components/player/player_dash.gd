extends State

const DASH_TIME := 0.12 

var timer := 0.0

func _ready():
	is_uninterruptible = true

func enter():
	timer = DASH_TIME
	velocity_component.dash(input.get_input_direction())

func physics_update(delta):
	timer -= delta
	if timer <= 0:
		velocity_component.stop_move()
		if input.get_input_direction() == Vector2.ZERO:
			Transitioned.emit(self, "Idle")
		else:
			Transitioned.emit(self, "Move")
