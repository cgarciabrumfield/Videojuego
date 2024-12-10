extends Control

@onready var mapNode
var treeSituation = false #treeSituation tiene que ser false cuando los nodos no estén pausados, y true cuando lo estén
var pauseMenuShows = false
var save_path = "res://saves/"

func _ready() -> void:
	mapNode = self.get_parent().get_parent().get_node("CanvasLayer2").get_node("Map")
	$AnimationPlayer.play("RESET")

func _process(_delta: float) -> void:
	
	listener()

#pauses and makes the pause menu visible
func resume():
	if !mapNode.map_visible:
		get_tree().paused = false
	pauseMenuShows = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	if !mapNode.map_visible:
		get_tree().paused = true
	pauseMenuShows = true
	$AnimationPlayer.play("blur")

func listener():
	if !get_tree().paused: #si el arbol no esta pausado es falso porque queremos que se pueda pausar 
		treeSituation = false 
	elif get_tree().paused and !pauseMenuShows: #si el menu no se muestra y el arbol esta pausao
		treeSituation = false
	else:
		treeSituation = true
	
	#La logica de pausa funciona junto al mapa
	#problema 1: no se cierra la ventana, está invisible pero ahí
	if Input.is_action_just_pressed("pause") and !treeSituation: #-> si el arbol no está pausado
		$SFX/pause_sfx.play()
		pause()
	elif Input.is_action_just_pressed("pause") and treeSituation: #-> si el arbol está pausado
		$SFX/resume_sfx.play()
		resume()

func _on_resume_pressed() -> void:
	if pauseMenuShows:
		$SFX/resume_sfx.play()
		resume()

func _on_quit_pressed() -> void:
	if pauseMenuShows:
		get_tree().quit()


func _on_save_pressed() -> void:
	GameState.save_game()
	pass # Replace with function body.
