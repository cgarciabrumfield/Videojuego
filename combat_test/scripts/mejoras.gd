class_name Mejoras
extends Control

var MEJORAS_RUTA = "res://mejoras.json"
var max_numero_mejoras
@onready var player = Globals.get_player_node(self)  # Accede al nodo player
var mejora_1_valor
var mejora_2_valor
var mejora_3_valor
var stat_1
var stat_2
var stat_3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	desactiva_nodo()
	var random = RandomNumberGenerator.new()
	random.randomize()
	var json_text = FileAccess.open(MEJORAS_RUTA, FileAccess.READ).get_as_text()

	var data = JSON.parse_string(json_text)
	
	var mejoras_data = data["mejoras"]
	var max_numero_mejoras = mejoras_data.size()
	
	# escogemos que mejoras aparecen de entre todas
	var mejoras = []

	while mejoras.size() < 3:
		var num = randi_range(0, max_numero_mejoras-1)
		if not num in mejoras:
			mejoras.append(num)
	
	# Inicializa las variables
	var mejora_1_titulo = $contenedor/mejora_1/fondo/titulo
	var mejora_1_descripcion = $contenedor/mejora_1/fondo/titulo/descripcion

	# Obtén datos del JSON
	mejora_1_valor = mejoras_data[mejoras[0]]["valor"][randi_range(0, 2)]  # Selección del valor adecuado
	stat_1 = mejoras_data[0]["stat"]

	# Asigna el texto del título y la descripción
	mejora_1_titulo.text = mejoras_data[mejoras[0]]["nombre"]

	mejora_1_descripcion.text = str(mejoras_data[mejoras[0]]["descripcion_start"]) \
	+ str(mejora_1_valor) \
	+ str(mejoras_data[mejoras[0]]["descripcion_end"])

	# Mejora 2
	var mejora_2_titulo = $contenedor/mejora_2/fondo/titulo
	var mejora_2_descripcion = $contenedor/mejora_2/fondo/titulo/descripcion

	mejora_2_valor = mejoras_data[mejoras[1]]["valor"][randi_range(0, 2)]  # Selección del valor adecuado
	stat_2 = mejoras_data[mejoras[1]]["stat"]

	mejora_2_titulo.text = mejoras_data[mejoras[1]]["nombre"]

	mejora_2_descripcion.text = str(mejoras_data[mejoras[1]]["descripcion_start"]) \
	+ str(mejora_2_valor) \
	+ str(mejoras_data[mejoras[1]]["descripcion_end"])

	# Mejora 3
	var mejora_3_titulo = $contenedor/mejora_3/fondo/titulo
	var mejora_3_descripcion = $contenedor/mejora_3/fondo/titulo/descripcion

	mejora_3_valor = mejoras_data[mejoras[2]]["valor"][randi_range(0, 2)]  # Selección del valor adecuado
	stat_3 = mejoras_data[mejoras[2]]["stat"]

	mejora_3_titulo.text = mejoras_data[mejoras[2]]["nombre"]

	mejora_3_descripcion.text = str(mejoras_data[mejoras[2]]["descripcion_start"]) \
	+ str(mejora_3_valor) \
	+ str(mejoras_data[mejoras[2]]["descripcion_end"])
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func _on_mejora_1_pressed() -> void:
	var original = player.get(stat_1)
	player.set(stat_1, original + mejora_1_valor)
	player.update_stats()
	player.healthbar.update()
	player.damagebar.update()
	reinicia_nodo()
	pass # Replace with function body.


func _on_mejora_2_pressed() -> void:
	var original = player.get(stat_2)
	player.set(stat_2, original + mejora_2_valor)
	player.update_stats()
	player.healthbar.update()
	player.damagebar.update()
	reinicia_nodo()
	pass # Replace with function body.


func _on_mejora_3_pressed() -> void:
	var original = player.get(stat_3)
	player.set(stat_3, original + mejora_3_valor)
	player.update_stats()
	player.healthbar.update()
	player.damagebar.update()
	reinicia_nodo()
	pass # Replace with function body.

func desactiva_nodo():
	self.visible = false  # Haz que el nodo sea visible
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Permite interacción del mouse		
	pass
	
func activa_nodo():
	self.visible = true  # Haz que el nodo sea visible
	self.mouse_filter = Control.MOUSE_FILTER_PASS  # Permite interacción del mouse		
	pass

func sube_nivel() -> void:
	activa_nodo()

# se encarga de dar nuevas mejoras para la siguiente llamada 
func reinicia_nodo():
	_ready()
	pass
