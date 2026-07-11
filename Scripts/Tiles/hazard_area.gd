extends Area2D
class_name hazard_area

@export var damage: float = 2.00

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_entered(area: HitboxComponent) -> void:
	if area is HitboxComponent:
		area.health_component.take_damage(damage)
		print(area.velocity_component)
		area.velocity_component.knockback(1000, global_position)
