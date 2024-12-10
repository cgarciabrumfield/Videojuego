extends Node2D

#TODO https://github.com/cgarciabrumfield/Videojuego/issues/64
@onready var nodo_Player = $level/Player
var level = GameState.level #este nombre debe coincidir con el de los archivos

func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
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
