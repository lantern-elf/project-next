extends AttackComponent
#attack for enemy

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent:
		for other in get_overlapping_areas():
			if other is BlockComponent:
				return
			
		area.health_component.take_damage(attack_damage, 200, global_position, 0.1, 0.25)
