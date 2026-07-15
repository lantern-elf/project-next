extends Area2D
class_name AttackComponent

"""
An (Area2D) component attached to an Player's weapon or attack.
When this area comes into contact with the HitboxComponent of
another emeny's Hitbox, damage is dealt to that enemy.
"""

@export var body: CharacterBody2D
@export var velocity_component: VelocityComponent
@export var attack_damage: float = 1.00
