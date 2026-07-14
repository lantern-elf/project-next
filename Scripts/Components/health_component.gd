extends Node
class_name HealthComponent

"""
Component managing an entity's health (HP): handling damage intake,
healing processes, flash effects upon taking hits, and the process 
of death.
"""

@export var body: CharacterBody2D
@export var body_sprite: Sprite2D
@export var velocity_component: VelocityComponent
@export var state_machine: StateMachine
@export var max_health: float = 3.0
@export var current_health: float = 3.0

var last_knockback_power: float
var last_knockback_source: Vector2
var last_knockback_duration: float

var damage_cooldown: bool = false

signal damaged

func take_damage(amount: float = 1.00, damage_knockback_power: float = 0.00, damage_knockback_source: Vector2 = Vector2.ZERO, damage_knockback_duration: float = .1, cooldown_duration: float = 1.0) -> void:
	last_knockback_power = damage_knockback_power
	last_knockback_source = damage_knockback_source
	last_knockback_duration = damage_knockback_duration
		
	if current_health <= 0 or damage_cooldown:
		return
		
	current_health -= amount
		
	if state_machine and state_machine.current_state.name != "Hurt":
		state_machine.current_state.Transitioned.emit(state_machine.current_state, "Hurt")
		
	damaged.emit()
	flash_hit()
		
	if current_health <= 0:
		die()
		return 
		
	damage_cooldown = true
	await get_tree().create_timer(cooldown_duration, true, false, true).timeout
	damage_cooldown = false

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)

func die() -> void:
	body.queue_free()

func flash_hit() -> void:
	var shader_mat := body_sprite.material
	shader_mat.set_shader_parameter("hit_flash_on", true)
	await get_tree().create_timer(.2, true, false, true).timeout
	shader_mat.set_shader_parameter("hit_flash_on", false)
