extends Node2D

# Variables que hacen referencia a los personajes (se inicializan en _ready)
var personaje1
var personaje2
var camera

# Nodo que hace referencia a la sala
var sala
var sprite
var sprite_size

func _ready():
	# Inicializamos los nodos dentro del _ready, una vez que toda la escena está cargada1
	personaje1 = $black_knight
	personaje2 = $knight
	sala = $sala
	sprite = $sala/Suelo
	sprite_size = sprite.texture.get_size()
	camera = $Camera2D
	camera.position = sprite.position # Ajusta según el tamaño de la sala
	
	
	spawn_personajes()

func spawn_personajes():
	# Definir un área de spawn basado en el nodo Sala (puedes ajustarlo según las dimensiones de tu sala)
	var area_min = sprite.position - sprite_size/2 # Cambia si la sala está desplazada
	var area_max = sprite.position + sprite_size/2 # Ajusta esto según el tamaño de tu sala
	
	# Posiciona a los personajes dentro de esta área
	personaje1.position = get_random_position(area_min, area_max)
	personaje2.position = get_random_position(area_min, area_max)

# Función para obtener una posición aleatoria dentro del área
func get_random_position(min_pos: Vector2, max_pos: Vector2) -> Vector2:
	var random_x = randf_range(min_pos.x, max_pos.x)
	var random_y = randf_range(min_pos.y, max_pos.y)
	return Vector2(random_x, random_y)
