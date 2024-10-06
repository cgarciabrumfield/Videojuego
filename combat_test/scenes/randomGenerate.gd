extends Node2D

# Variables
const SALA_SCENE = preload("res://scenes/salaGeneral.tscn")
const PASILLO_HORIZONTAL_SCENE = preload("res://scenes/pasilloHorizontal.tscn")
const PASILLO_VERTICAL_SCENE = preload("res://scenes/pasilloVertical.tscn")
const CIERRE_HORIZONTAL_SCENE = preload("res://scenes/cierreParedH.tscn")
const CIERRE_VERTICAL_SCENE = preload("res://scenes/cierreParedV.tscn")

const SALA_SIZE = Vector2(1000, 1000)
const PASILLO_HORIZONTAL_SIZE = Vector2(1000, 120)
const PASILLO_VERTICAL_SIZE = Vector2(120, 1000)
const MAPA_SIZE = Vector2(10000, 10000)
var numSalas = randi() % 11 + 5

var salas = []
var conexiones = {}
var camera

# Método para inicializar el juego
func _ready():
	camera = $Camera2D
	generar_salas(numSalas)
	conectar_salas()  # Conectar salas en forma de árbol
	asegurar_conexiones_minimas()  # Asegurar conexiones mínimas
	agregar_conexiones_adicionales()  # Agregar conexiones adicionales
	agregar_cierres()  # Agregar cierres en los lados sin conexiones

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

	movimiento = movimiento.normalized() * 500 * delta
	camera.position += movimiento

func generar_salas(num_salas):
	var i = 0
	while i < num_salas:
		var sala = SALA_SCENE.instantiate()
		var posicion = Vector2.ZERO

		if i == 0:
			posicion = Vector2.ZERO
		else:
			var salaActual = salas[i - 1]
			if i > 1:
				salaActual = salas[randi() % i]
			if randi() % 2 == 0:
				posicion.x = salaActual.x
				posicion.y = salaActual.y + SALA_SIZE.y + 940
			else:
				posicion.x = salaActual.x + SALA_SIZE.x + 940
				posicion.y = salaActual.y

		if es_posicion_valida(posicion):
			sala.position = posicion
			add_child(sala)
			salas.append(posicion)
			conexiones[i] = []
			i += 1

func es_posicion_valida(posicion):
	for sala in salas:
		if (posicion.x < sala.x + SALA_SIZE.x and
			posicion.x + SALA_SIZE.x > sala.x and
			posicion.y < sala.y + SALA_SIZE.y and
			posicion.y + SALA_SIZE.y > sala.y):
			return false
	return true

# Función para conectar salas en forma de árbol
func conectar_salas():
	if salas.size() < 2:
		return

	var indices_conectados = [0]  # Comenzamos con la primera sala conectada
	var salas_por_conectar = []

	for i in range(1, salas.size()):
		salas_por_conectar.append(i)

	while salas_por_conectar.size() > 0:
		var sala_index = salas_por_conectar[randi() % salas_por_conectar.size()]
		var sala_conectada_index = indices_conectados[randi() % indices_conectados.size()]

		# Conectar solo si están a distancia
		if (abs(salas[sala_index].x - salas[sala_conectada_index].x) <= 1940 and abs(salas[sala_index].y - salas[sala_conectada_index].y) <= 10) or (abs(salas[sala_index].y - salas[sala_conectada_index].y) <= 1940 and abs(salas[sala_index].x - salas[sala_conectada_index].x) <= 10):

			print("Conectando: ", sala_index, " con ", sala_conectada_index)
			conexiones[sala_index].append(sala_conectada_index)
			conexiones[sala_conectada_index].append(sala_index)
			crear_pasillo(salas[sala_index], salas[sala_conectada_index])

			# Agregar la sala conectada a las conectadas
			if !indices_conectados.has(sala_index):
				indices_conectados.append(sala_index)

			# Eliminar la sala de la lista de salas por conectar
			salas_por_conectar.erase(sala_index)

func crear_pasillo(pos_a, pos_b):
	var pasillo

	if pos_a.x == pos_b.x:
		var max = max(pos_a.y, pos_b.y)
		var min = min(pos_a.y, pos_b.y)
		pasillo = PASILLO_VERTICAL_SCENE.instantiate()
		pasillo.position = Vector2(pos_a.x, (max - min) / 2 + min)
	else:
		var max = max(pos_a.x, pos_b.x)
		var min = min(pos_a.x, pos_b.x)
		pasillo = PASILLO_HORIZONTAL_SCENE.instantiate()
		pasillo.position = Vector2((max - min) / 2 + min, pos_a.y)

	add_child(pasillo)

# Función para asegurar que todas las salas estén conectadas al menos una vez
func asegurar_conexiones_minimas():
	if salas.size() == 0:
		return
	
	# Lista de salas no conectadas
	var no_conectadas = []
	for i in range(salas.size()):
		if conexiones[i].size() == 0:
			no_conectadas.append(i)

	# Conectar cada sala no conectada a una sala conectada aleatoria
	for sala_index in no_conectadas:
		var sala_conectada_index = randi() % salas.size()
		while sala_conectada_index == sala_index or conexiones[sala_conectada_index].size() == 0:
			sala_conectada_index = randi() % salas.size()
		
		print("Conectando sala no conectada: ", sala_index, " con sala: ", sala_conectada_index)
		conexiones[sala_index].append(sala_conectada_index)
		conexiones[sala_conectada_index].append(sala_index)
		crear_pasillo(salas[sala_index], salas[sala_conectada_index])
		
# Función para agregar conexiones adicionales
func agregar_conexiones_adicionales():
	if salas.size() < 2:  # Solo intentar conectar si hay al menos dos salas
		return

	for i in range(salas.size()):
		var sala_a = salas[i]

		for j in range(i + 1, salas.size()):  # Solo verificar las salas a la derecha
			var sala_b = salas[j]

			# Verificar si las salas están a 940 unidades de distancia en X o Y
			if abs(sala_a.x - sala_b.x) <= 1940 and abs(sala_a.y - sala_b.y) <= 10:
				if randi() % 2 == 1:
					print("Conectando: ", sala_a, " con ", sala_b)  # Mensaje de depuración
				
					crear_pasillo(sala_a, sala_b)
					
					# Actualizar las conexiones para ambas salas
					conexiones[i].append(j)
					conexiones[j].append(i)
			elif abs(sala_a.y - sala_b.y) <= 1940 and abs(sala_a.x - sala_b.x) <= 10:
				if randi() % 2 == 1:
					print("Conectando: ", sala_a, " con ", sala_b)  # Mensaje de depuración
				
					crear_pasillo(sala_a, sala_b)
					
					# Actualizar las conexiones para ambas salas
					conexiones[i].append(j)
					conexiones[j].append(i)


# Nueva función para agregar cierres en las paredes no conectadas
func agregar_cierres():
	for i in range(salas.size()):
		var sala = salas[i]
		var sala_conexiones = conexiones[i]

		# Verificar en cada dirección (norte, sur, este, oeste)
		var norte_conectado = false
		var sur_conectado = false
		var este_conectado = false
		var oeste_conectado = false

		for conexion_index in sala_conexiones:
			var sala_conectada = salas[conexion_index]
			if sala_conectada.x == sala.x and sala_conectada.y < sala.y:
				norte_conectado = true
			elif sala_conectada.x == sala.x and sala_conectada.y > sala.y:
				sur_conectado = true
			elif sala_conectada.x > sala.x and sala_conectada.y == sala.y:
				este_conectado = true
			elif sala_conectada.x < sala.x and sala_conectada.y == sala.y:
				oeste_conectado = true

		# Agregar cierre en los lados que no están conectados
		if !norte_conectado:
			var cierre_norte = CIERRE_VERTICAL_SCENE.instantiate()
			cierre_norte.position = Vector2(sala.x, sala.y - SALA_SIZE.y / 2 + 15)
			add_child(cierre_norte)
		if !sur_conectado:
			var cierre_sur = CIERRE_VERTICAL_SCENE.instantiate()
			cierre_sur.position = Vector2(sala.x, sala.y + SALA_SIZE.y / 2 - 15)
			add_child(cierre_sur)
		if !este_conectado:
			var cierre_este = CIERRE_HORIZONTAL_SCENE.instantiate()
			cierre_este.position = Vector2(sala.x + SALA_SIZE.x / 2 - 15, sala.y)
			add_child(cierre_este)
		if !oeste_conectado:
			var cierre_oeste = CIERRE_HORIZONTAL_SCENE.instantiate()
			cierre_oeste.position = Vector2(sala.x - SALA_SIZE.x / 2 + 15, sala.y)
			add_child(cierre_oeste)
