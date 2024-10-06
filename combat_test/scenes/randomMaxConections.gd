extends Node2D

# Variables
const SALA_SCENE = preload("res://scenes/salaGeneral.tscn")  # Ruta a la escena de la sala
const PASILLO_HORIZONTAL_SCENE = preload("res://scenes/pasilloHorizontal.tscn")  # Ruta a la escena de pasillo horizontal
const PASILLO_VERTICAL_SCENE = preload("res://scenes/pasilloVertical.tscn")  # Ruta a la escena de pasillo vertical

const SALA_SIZE = Vector2(1000, 1000)           # Dimensiones de la sala
const PASILLO_HORIZONTAL_SIZE = Vector2(1000, 120)  # Dimensiones del pasillo horizontal
const PASILLO_VERTICAL_SIZE = Vector2(120, 1000)    # Dimensiones del pasillo vertical
const MAPA_SIZE = Vector2(10000, 10000)  # Tamaño total del mapa
var numSalas = randi() % 11 + 5

var salas = []

# Referencia a la cámara
var camera  # Asegúrate de que Camera2D esté como hijo de este nodo

# Método para inicializar el juego
func _ready():
	camera = $Camera2D
	generar_salas(numSalas)  
	conectar_salas()

# Función para mover la cámara con las teclas de dirección
func _process(delta):
	var movimiento = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		movimiento.x += 1
	if Input.is_action_pressed("ui_left"):
		movimiento.x -= 1
	if Input.is_action_pressed("ui_down"):
		movimiento.y += 1
	if Input.is_action_pressed("ui_up"):
		movimiento.y -= 1

	movimiento = movimiento.normalized() * 500 * delta  # Ajustar la velocidad de movimiento
	camera.position += movimiento

# Función para generar salas
# Función para generar salas
# Función para generar salas
func generar_salas(num_salas):
	var i = 0
	while i < num_salas:
		var sala = SALA_SCENE.instantiate()  # Instanciar la sala
		var posicion = Vector2.ZERO

		if i == 0:  # La primera sala se coloca en una posición fija
			posicion = Vector2.ZERO
			
		else:
			var salaActual = salas[i - 1]
			if i > 1:
				salaActual = salas[randi() % i]     
			# Generar una sala alineada con las anteriores
			if randi() % 2 == 0:  # Elige aleatoriamente si se alinea horizontal o verticalmente
				# Alinear horizontalmente
				posicion.x = salaActual.x  # Compartir coordenada X
				posicion.y = salaActual.y + SALA_SIZE.y + 940  # Dejar 940 unidades de distancia en Y
			else:
				# Alinear verticalmente
				posicion.x = salaActual.x + SALA_SIZE.x + 940  # Dejar 940 unidades de distancia en X
				posicion.y = salaActual.y  # Compartir coordenada Y

		# Verifica si la posición está libre de otras salas
		if es_posicion_valida(posicion):
			sala.position = posicion
			add_child(sala)
			salas.append(posicion)
			i += 1  # Solo incrementar i si la sala fue válida
		else:
			print("Posición inválida, intentando generar la misma sala nuevamente: ", i)



# Función para verificar si la posición de la sala es válida
func es_posicion_valida(posicion):
	# Comprobar si la nueva sala se superpone con alguna existente
	for sala in salas:
		if (posicion.x < sala.x + SALA_SIZE.x and
			posicion.x + SALA_SIZE.x > sala.x and
			posicion.y < sala.y + SALA_SIZE.y and
			posicion.y + SALA_SIZE.y > sala.y):
			return false
	return true

# Función para conectar las salas con pasillos
func conectar_salas():
	if salas.size() < 2:  # Solo intentar conectar si hay al menos dos salas
		return

	for i in range(salas.size()):
		var sala_a = salas[i]

		for j in range(i + 1, salas.size()):  # Solo verificar las salas a la derecha
			var sala_b = salas[j]

			# Verificar si las salas están a 940 unidades de distancia en X o Y
			if abs(sala_a.x - sala_b.x) <= 1940 and abs(sala_a.y - sala_b.y) <= 10:
				print("Conectando: ", sala_a, " con ", sala_b)  # Mensaje de depuración
				crear_pasillo(sala_a, sala_b)
			elif abs(sala_a.y - sala_b.y) <= 1940 and abs(sala_a.x - sala_b.x) <= 10:
				print("Conectando: ", sala_a, " con ", sala_b)  # Mensaje de depuración
				crear_pasillo(sala_a, sala_b)


# Función para crear un pasillo entre dos salas
func crear_pasillo(pos_a, pos_b):
	var pasillo

	# Decide si el pasillo será horizontal o vertical
	if pos_a.x == pos_b.x:  # Si tienen la misma coordenada X, el pasillo es horizontal
		var max = max(pos_a.y, pos_b.y)
		var min = min(pos_a.y, pos_b.y)
		pasillo = PASILLO_VERTICAL_SCENE.instantiate()  # Instanciar el pasillo horizontal
		pasillo.position = Vector2(pos_a.x, (max - min)/2 + min)
	else:  # Si tienen la misma coordenada Y, el pasillo es vertical
		var max = max(pos_a.x, pos_b.x)
		var min = min(pos_a.x, pos_b.x)
		pasillo = PASILLO_HORIZONTAL_SCENE.instantiate()  # Instanciar el pasillo vertical
		pasillo.position = Vector2((max - min)/2 + min, pos_a.y)

	add_child(pasillo)
