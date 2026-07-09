class_name State extends Node

@export var body: CharacterBody2D 
@export var state_machine: StateMachine
@export var animation_player: AnimationPlayer
@export var velocity_component: VelocityComponent
@export var input: InputComponent #assign to input component if needed

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
