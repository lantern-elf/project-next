extends State

var anim_state

func _ready():
	is_uninterruptible = true

func enter():
	PlayerActionManager.attack_state += 1
	if PlayerActionManager.attack_state > 4:
		PlayerActionManager.attack_state = 1
		
	anim_state = 1 if PlayerActionManager.attack_state % 2 != 0 else 2
	
	velocity_component.attack_move(input.get_input_direction())
	
	var dir = velocity_component.current_direction + str(anim_state)
	animation_player.play_animation("attack", dir)
	
	await animation_player.animation_finished
	Transitioned.emit(self, "Idle")
