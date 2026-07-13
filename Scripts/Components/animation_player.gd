extends AnimationPlayer

@export var body: CharacterBody2D
@export var body_sprite: Sprite2D

func play_animation(action: String, direction: String):
	var anim_name = "%s_%s" % [action, direction]
	if has_animation(anim_name):
		play(anim_name)
		return anim_name
	else:
		push_warning("Missing animation: %s" % anim_name)
