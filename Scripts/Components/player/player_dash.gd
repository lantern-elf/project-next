extends State

func enter():
	pass

func update(_delta: float):
	velocity_component.dash(input.get_input_direction())
	Transitioned.emit(self, "idle")
	pass

func physics_update(_delta: float):
	pass

func exit():
	pass
