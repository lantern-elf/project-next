extends Node
class_name HealthComponent

@export var body: CharacterBody2D
@export var body_sprite: Sprite2D
@export var max_health = 3.0
@export var current_health = 3.0

signal get_damage

func take_damage(amount: float):
	current_health -= amount
	get_damage.emit()
	flash_hit()
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health += amount
	if current_health > max_health:
		current_health = max_health 

func die():
	body.queue_free()

func flash_hit():
	body_sprite.material.set_shader_parameter("hit_flash_on", true)
	await get_tree().create_timer(.2, true, false, true).timeout
	body_sprite.material.set_shader_parameter("hit_flash_on", false)
