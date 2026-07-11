extends State

var anim_state

func enter():
	PlayerActionManager.attack_state += 1
	if PlayerActionManager.attack_state > 4:
		PlayerActionManager.attack_state = 1

	anim_state = 1 if PlayerActionManager.attack_state % 2 != 0 else 2
	
	var dir = velocity_component.current_direction + str(anim_state)
	animation_player.play_animation("attack", dir)
	
	await animation_player.animation_finished
	#await get_tree().create_timer(.3).timeout
	Transitioned.emit(self, "Idle")


func physics_update(_delta: float):
	velocity_component.attack_move(input.get_input_direction())

func exit():
	velocity_component.stop_move()
