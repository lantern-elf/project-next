extends VelocityComponent

var is_knockbacked: bool = false

func _ready() -> void:
	pass # Replace with function body.

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	if not is_knockbacked:
		body.velocity = Vector2.DOWN * 50
	body.move_and_slide()

func knockback(power, source):
	is_knockbacked = true
	var knockback_direction = (body.global_position - source).normalized() 
	body.velocity = knockback_direction * power
	await get_tree().create_timer(0.1).timeout
	stop_move()
	is_knockbacked = false
