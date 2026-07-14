extends AnimationPlayer

"""
Automatically construct an animation name based on
a combination of "action" and "direction," then play
that animation if it exists.

Example:
play_animation("idle", "down") will attempt to play
the animation named "idle_down".
"""

@export var body: CharacterBody2D
@export var body_sprite: Sprite2D

func play_animation(action: String, direction: String):
	var anim_name = "%s_%s" % [action, direction]
	if has_animation(anim_name):
		play(anim_name)
		return anim_name
	else:
		push_warning("Missing animation: %s" % anim_name)
