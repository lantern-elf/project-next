extends State

func enter():
	pass

func update(_delta: float):
	var direction = velocity_component.current_direction
	animation_player.play_animation("idle", direction)

func physics_update(_delta: float):
	if input.get_input_direction() != Vector2.ZERO:
		Transitioned.emit(self, "Move")
