extends State

func enter():
	pass

func update(_delta):
	var direction = velocity_component.current_direction
	animation_player.play_animation("move", direction)

func physics_update(_delta):
	velocity_component.move(input.get_input_direction())
	if input.get_input_direction() == Vector2.ZERO:
		Transitioned.emit(self, "Idle")
