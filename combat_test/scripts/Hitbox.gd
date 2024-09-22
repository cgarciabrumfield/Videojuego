class_name Hitbox
extends Area2D

@export var damage = 10
@export var knockback = 100
@export var can_be_parried = false

func _ready() -> void:
	collision_mask = 0
	collision_layer = 2
