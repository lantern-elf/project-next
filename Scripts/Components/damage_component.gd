extends Area2D

@export var body: CharacterBody2D
@export var attack_damage: float = 1.00

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent and area.is_in_group("Hitable") and not area.is_in_group("player"):
		area.health_component.take_damage(attack_damage)
		area.get_parent().velocity_component.knockback(100, body.velocity_component.get_direction_vector())
