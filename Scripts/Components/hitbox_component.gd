extends Area2D
class_name HitboxComponent

"""
An (Area2D) component that defines the "body area" of an entity 
susceptible to external attacks (such as an enemy's `damage_component` 
or a hazard area like spikes or fire). This component contains no logic 
of its own; it merely stores references to the body and other components
required when the area is hit by an attack.
"""

@export var body: CharacterBody2D
@export var health_component: HealthComponent
@export var velocity_component: VelocityComponent
