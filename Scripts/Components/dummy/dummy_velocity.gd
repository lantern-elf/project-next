extends VelocityComponent

var is_knockbacked: bool = false

func _ready() -> void:
	body.health_component.get_damage.connect(on_body_get_damage)

@warning_ignore("unused_parameter")
func _physics_process(delta):
	if is_knockbacked:
		body.move_and_slide()
		return
	body.velocity = Vector2.ZERO
	body.move_and_slide()

func knockback(power, source, duration = .1):
	is_knockbacked = true
	var knockback_direction = (body.global_position - source).normalized() 
	body.velocity = knockback_direction * power
	await get_tree().create_timer(duration).timeout
	stop_move()
	knockback_finished.emit()
	is_knockbacked = false

func on_body_get_damage():
	var power = body.health_component.last_knockback_power
	var source = body.health_component.last_knockback_source
	var duration = body.health_component.last_knockback_duration
	
	knockback(power, source, duration)
	
