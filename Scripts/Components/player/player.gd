extends CharacterBody2D

#@onready var state_machine = $StateMachine
#@onready var PLInput = $InputComponent

@export var velocity_component: VelocityComponent 
@export var health_component: HealthComponent
@export var hitbox_component: HitboxComponent 
@export var state_machine: StateMachine 
@export var animation_player: AnimationPlayer 
@export var input_component: InputComponent

var no_attack_time := 0.0
const attack_RESET_DELAY := 1.0

func _process(delta: float) -> void:
	if input_component.attack():
		no_attack_time = 0.0
		
		if PlayerActionManager.can_attack:
			PlayerActionManager.lock_attack(0.3)
			state_machine.current_state.Transitioned.emit(state_machine.current_state, "Attack")
	else:
		no_attack_time += delta
		
		if no_attack_time >= attack_RESET_DELAY:
			PlayerActionManager.reset_attack_state()
	
	if input_component.dash():
		state_machine.current_state.Transitioned.emit(state_machine.current_state, "Dash")
