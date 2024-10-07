class_name Player_Hitbox
extends Area2D

@export var damage = 1
@export var knockback = 100

func _ready() -> void:
	collision_mask = 0
	collision_layer = 2
