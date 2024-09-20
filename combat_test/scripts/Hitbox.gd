class_name Hitbox
extends Area2D

@export var damage = 10
@export var knockback = 100

func _ready() -> void:
	collision_mask = 0
	collision_layer = 2
