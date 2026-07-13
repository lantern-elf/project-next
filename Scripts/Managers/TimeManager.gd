extends Node

func hit_stop():
	Engine.time_scale = 0
	await get_tree().create_timer(.1, true, false, true).timeout
	Engine.time_scale = 1

func freeze():
	Engine.time_scale = 0
	await get_tree().create_timer(1, true, false, true).timeout
	Engine.time_scale = 1
