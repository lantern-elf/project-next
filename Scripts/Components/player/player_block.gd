extends State

@export var block_component: BlockComponent

func enter():
	block_component.collider.disabled = false
	print("block")

func update(_delta: float):
	var dir =  velocity_component.current_direction
	var act1 = "block"
	var act2 = ""
	if input.get_input_direction() == Vector2.ZERO:
		act2 = "idle"
	else :
		act2 = "move"
		
	var act = act2 + act1
	
	animation_player.play_animation(act, dir)
	if not input.block():
		Transitioned.emit(self, "idle")
	pass

func physics_update(_delta: float):
	velocity_component.move(input.get_input_direction())

func exit():
	block_component.collider.disabled = true
	print("not block")
	
