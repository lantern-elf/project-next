extends AttackComponent

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent and area.is_in_group("Hitable") and not area.is_in_group("Player"):
		area.health_component.take_damage(attack_damage, 200, global_position, 0.1, 0.25)
		TimeManager.hit_stop()

#func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	#if body is TileMapLayer:
		#var coords = body.get_coords_for_body_rid(body_rid)
		#var tile_world_pos = body.to_global(body.map_to_local(coords))
		#print(tile_world_pos)
		#velocity_component.bounce(tile_world_pos)
