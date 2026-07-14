extends State

var last_knockback_power: float
var last_knockback_source: Vector2
var last_knockback_duration: float

func enter():
	if health_component.last_knockback_power and health_component.last_knockback_power and health_component.last_knockback_duration:
		last_knockback_power = health_component.last_knockback_power
		last_knockback_source = health_component.last_knockback_source
		last_knockback_duration = health_component.last_knockback_duration

func physics_update(_delta: float):
	velocity_component.knockback(last_knockback_power, last_knockback_source, last_knockback_duration)
	await velocity_component.knockback_finished
	Transitioned.emit(self, "idle")
