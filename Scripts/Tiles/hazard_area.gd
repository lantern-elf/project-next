extends Area2D
class_name hazard_area

@export var damage: float = 1.00
@export var knockback_power: = 200.00
@export var can_be_blocked: bool = true

var areas_to_affected: Array = []

func _physics_process(_delta: float) -> void:
	var overlaps := get_overlapping_areas()
			
	if can_be_blocked:
		for area in overlaps:
			if area is BlockComponent:
				return
			
	for area in overlaps:
		if area is HitboxComponent and area.health_component:
			area.health_component.take_damage(damage, knockback_power, global_position)

func _on_area_entered(area: Area2D) -> void:
	if area is HitboxComponent and area.health_component:
		areas_to_affected.append(area)

func _on_area_exited(area: Area2D) -> void:
	if is_instance_valid(area):
		areas_to_affected.erase(area)
