extends Node2D

var save_path = "user://knightsCurse.save" 
#TODO https://github.com/cgarciabrumfield/Videojuego/issues/64

var level = "bosque" #este nombre debe coincidir con el de los archivos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var level_node = $level
	level_node.load_level(level)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func save():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	#TODO https://github.com/cgarciabrumfield/Videojuego/issues/64
