extends Node
class_name HealthComponent

@export var body: CharacterBody2D

@export var max_health = 3.0
@export var current_health = 3.0

signal get_damage

func take_damage(amount: float):
	current_health -= amount
	get_damage.emit()
	if current_health <= 0:
		die()

func heal(amount: float):
	current_health += amount
	if current_health > max_health:
		current_health = max_health 

func die():
	body.queue_free()
