extends Node
class_name StateMachine

"""
A simple Finite State Machine (FSM) implementation for Godot.
Any child node of this node that is of the "State" type will
automatically be registered as a valid state.
This state machine manages transitions between states (Idle,
Move, Attack, etc.) based on the "Transitioned" signal from the active state. 
"""

@export var initial_state : State
@export var current_state : State
var states : Dictionary = {}  # Store states by name for lookup

func _ready() -> void:
	for child in get_children():
		if child is State:
			# Store each State in the dictionary, using lowercase of its name as the key
			states[child.name.to_lower()] = child
			# Connect state's Transitioned signal to the handler
			child.Transitioned.connect(on_child_transition)
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func on_child_transition(state, new_state_name):
	# Only process transition if it's from the currently active state
	if state != current_state:
		return

	var new_state = states.get(new_state_name.to_lower()) 
	if !new_state:
		return  # No such state found

	if current_state:
		current_state.exit()  # Call Exit on the current state

	current_state = new_state  # Update the current state reference
	new_state.enter()  # Enter the new state
