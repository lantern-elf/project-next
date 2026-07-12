extends Area2D
class_name hazard_area

@export var damage: float = 0.1
@export var knockback_power: = 200.00

var areas_to_affected: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	for area in areas_to_affected.duplicate():
		if not is_instance_valid(area) or not is_instance_valid(area.health_component):
			areas_to_affected.erase(area)
			continue
		if area.health_component.current_health > 0:
				area.health_component.take_damage(damage, knockback_power, global_position)

func _on_area_entered(area: HitboxComponent) -> void:
	if area is HitboxComponent and area.health_component:
		areas_to_affected.append(area)

func _on_area_exited(area) -> void:
	if is_instance_valid(area):
		areas_to_affected.erase(area)
