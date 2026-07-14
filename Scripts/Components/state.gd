class_name State extends Node

"""
Base class for all states in the State Machine pattern
(e.g., Idle, Move, Attack, Dash, Hurt). Each derived state
simply overrides the enter/update/physics_update/exit functions
as needed and emits the Transitioned signal when it wants
to switch to another state.
"""

@export var body: CharacterBody2D 
@export var state_machine: StateMachine
@export var animation_player: AnimationPlayer
@export var velocity_component: VelocityComponent
@export var input: InputComponent #assign to input component if needed
@export var health_component: HealthComponent

@export var is_uninterruptible: bool = false

@warning_ignore("unused_signal")
signal Transitioned

func enter():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass

func exit():
	pass
