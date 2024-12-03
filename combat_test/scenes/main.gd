extends Node2D

var save_path = "user://knightsCurse.save" 
#TODO https://github.com/cgarciabrumfield/Videojuego/issues/64

var level = "cueva" #este nombre debe coincidir con el de los archivos

func save():
	var save_dict = {
		"level" : level
	}
	return save_dict

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var level_node = $level
	level_node.load_level(level)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
