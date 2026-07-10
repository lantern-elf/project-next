extends VelocityComponent


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	body.move_and_slide()
	pass
