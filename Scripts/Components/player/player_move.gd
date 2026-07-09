extends State

func enter():
	pass

func update(_delta):
	var direction = velocity_component.current_direction
	animation_player.play_animation("move", direction)

func physics_update(_delta):
	velocity_component.move(input.get_input_direction()) # Moving the player based on input
	
	# Trigger for trantiton to idle state
	if input.get_input_direction() == Vector2.ZERO:
		#await get_tree().create_timer(0.1).timeout #await for the animation doesn't change immediately
		#await animation_player.animation_finished
		Transitioned.emit(self, "Idle")
