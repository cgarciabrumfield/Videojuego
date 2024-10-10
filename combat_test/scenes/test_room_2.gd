extends Node2D
#Lista de booleanos Norte Sur Este Oeste
var conexiones = []
var ya_explorada

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setConexions(conexions):
	conexiones = conexions
	
func visitada(visitado: bool):
	if !visitada:
		genera_enemigos()
		cierra_puertas()

func genera_enemigos():
	pass

func cierra_puertas():
	pass

func exit_room(direccion: String):
	#TODO animación salir
	get_parent().cambiar_sala(direccion)
