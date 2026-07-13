extends State

func enter():
	pass

func update(_delta):
	var direction = velocity_component.current_direction
	animation_player.play_animation("move", direction)

func physics_update(_delta):
	velocity_component.move(input.get_input_direction())
	if input.get_input_direction() == Vector2.ZERO:
		#await animation_player.animation_finished
		#await get_tree().create_timer(0.1).timeout #await for the animation doesn't change immediately
		Transitioned.emit(self, "Idle")
