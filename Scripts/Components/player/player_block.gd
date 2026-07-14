extends State

func enter():
	print("block")

func update(_delta: float):
	if not Input.is_action_pressed("block"):
		Transitioned.emit(self, "Idle")

func physics_update(_delta: float):
	pass

func exit():
	print("not_blcok")
