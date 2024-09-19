extends Node2D

var scene_knight = preload("res://scenes/knight.tscn")
var scene_slime = preload("res://scenes/slime.tscn")
var instance_knight = scene_knight.instantiate()
var instance_slime = scene_slime.instantiate()
var instance_slime2 = scene_slime.instantiate()
var instance_slime3 = scene_slime.instantiate()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(instance_knight)
	add_child(instance_slime)
	add_child(instance_slime2)
	add_child(instance_slime3)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
