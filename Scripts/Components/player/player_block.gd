extends State

@export var block_component: BlockComponent

func enter():
	velocity_component.lock_direction()
	block_component.collider.disabled = false

func update(_delta: float):
	var input_dir := input.get_input_direction()
	var act := ("idle" if input_dir == Vector2.ZERO else "move") + "block"
	
	animation_player.play_animation(act, velocity_component.facing_direction)
	
	if not input.block():
		Transitioned.emit(self, "idle")

func physics_update(_delta: float):
	velocity_component.move(input.get_input_direction(), 30)

func exit():
	velocity_component.unlock_direction()
	block_component.collider.disabled = true
