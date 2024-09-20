extends Node2D

var scene_slime = preload("res://scenes/slime.tscn")
var slimes = []
var player_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var instance_slime = scene_slime.instantiate()
	var instance_slime2 = scene_slime.instantiate()
	var instance_slime3 = scene_slime.instantiate()
	
	# Añade las instancias a la lista
	slimes.append(instance_slime)
	slimes.append(instance_slime2)
	slimes.append(instance_slime3)
	
	# Añade las instancias al árbol de nodos
	for slime in slimes:
		add_child(slime)

# Called every frame.
func _process(delta: float) -> void:
	# Llama al método `move` en cada instancia de slime
	for slime in slimes:
		if slime.is_inside_tree():
			slime.get_player_position($Player.position)
