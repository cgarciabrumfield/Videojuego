extends Node2D

var full_map = {}
var discovered_map = {}
var node_sprite = load("res://assets/minimapa/map_nodes1.png")
var branch_sprite = load("res://assets/minimapa/map_nodes2.png")
@onready var node_sprite_player = $CaballeroCabezabuque

var room = preload("res://scenes/bosque/forest_room.tscn")
var boss_room = preload("res://scenes/bosque/forest_boss_room.tscn")
@onready var map_node = $MapNode
@onready var player = $Player
@onready var camera = $Camera2D
const CAMERA_ZOOM = Vector2(5, 5)
var current_coords
var room_size = Vector2(320, 191.15)

var sala_inicio_coords
var sala_final_coords

func _ready():
	camera.zoom = CAMERA_ZOOM
	var seed = randi_range(-1000, 1000)
	print("seed: " + str(seed))
	full_map = generate(seed)
	var salas_mas_alejadas_coords = encontrar_salas_mas_alejadas()
	var num = randi_range(0,1)
	sala_inicio_coords = salas_mas_alejadas_coords[num]
	sala_final_coords = salas_mas_alejadas_coords[1-num]
	current_coords = sala_inicio_coords
	var a = full_map[sala_final_coords].connected_rooms
	full_map[sala_final_coords] = boss_room.instantiate()
	for clave in a.keys():
		if a[clave] != null:
			connect_rooms(full_map[sala_final_coords], full_map[sala_final_coords + clave], clave)
	discovered_map[current_coords] = full_map[current_coords]
	add_child(full_map[current_coords])
	load_map(discovered_map, 0)

var min_number_rooms = 6
var max_number_rooms = 10

var room_generation_chance = 20

func generate(room_seed):
	seed(room_seed)
	var dungeon = {}
	var size = randi_range(min_number_rooms, max_number_rooms)
	
	dungeon[Vector2(0,0)] = room.instantiate()
	for child in dungeon[Vector2(0,0)].get_node("enemigos").get_children():
		child.queue_free()
	size -= 1
	
	while(size > 0):
		for i in dungeon.keys():
			if(randi_range(0,100) < room_generation_chance):
				var direction = randi_range(0,4)
				if(direction < 1):
					var new_room_position = i + Vector2(1, 0)
					if(!dungeon.has(new_room_position)):
						dungeon[new_room_position] = room.instantiate()
						size -= 1
					if(dungeon.get(i).connected_rooms.get(Vector2(1, 0)) == null):
						connect_rooms(dungeon.get(i), dungeon.get(new_room_position), Vector2(1, 0))
				elif(direction < 2):
					var new_room_position = i + Vector2(-1, 0)
					if(!dungeon.has(new_room_position)):
						dungeon[new_room_position] = room.instantiate()
						size -= 1
					if(dungeon.get(i).connected_rooms.get(Vector2(-1, 0)) == null):
						connect_rooms(dungeon.get(i), dungeon.get(new_room_position), Vector2(-1, 0))
				elif(direction < 3):
					var new_room_position = i + Vector2(0, 1)
					if(!dungeon.has(new_room_position)):
						dungeon[new_room_position] = room.instantiate()
						size -= 1
					if(dungeon.get(i).connected_rooms.get(Vector2(0, 1)) == null):
						connect_rooms(dungeon.get(i), dungeon.get(new_room_position), Vector2(0, 1))
				elif(direction < 4):
					var new_room_position = i + Vector2(0, -1)
					if(!dungeon.has(new_room_position)):
						dungeon[new_room_position] = room.instantiate()
						size -= 1
					if(dungeon.get(i).connected_rooms.get(Vector2(0, -1)) == null):
						connect_rooms(dungeon.get(i), dungeon.get(new_room_position), Vector2(0, -1))
	while(!is_interesting(dungeon)):
		for i in dungeon.keys():
			dungeon.get(i).queue_free()
		var sed = room_seed * randi_range(-1,1) + randi_range(-100,100)
		dungeon = generate(sed)
	return dungeon

func connect_rooms(room1, room2, direction):
	room1.connected_rooms[direction] = room2
	room2.connected_rooms[-direction] = room1
	room1.number_of_connections += 1
	room2.number_of_connections += 1

func is_interesting(dungeon):
	var room_with_three = 0
	for i in dungeon.keys():
		if(dungeon.get(i).number_of_connections >= 3):
			room_with_three += 1
	return room_with_three >= 2

func calcular_distancia(inicio: Vector2, destino: Vector2) -> int:
	var cola = []
	var visitados = {}
	#Añadimos la sala de inicio
	cola.append({"coords": inicio, "distancia": 0})
	visitados[inicio] = true
	while cola.size() > 0:
		#print("\n")
		#print("Iteracion")
		var actual = cola.front()
		cola.pop_front()
		var sala_actual_coords = actual["coords"]
		var distancia_actual = actual["distancia"]
		#print("actual: " + str(actual))
		#print("sala_actual_pos: " + str(sala_actual_pos))
		#Si hemos llegado al destino
		if sala_actual_coords == destino:
			return distancia_actual
		#Obtener la sala actual desde el diccionario
		var sala_actual = full_map.get(sala_actual_coords)
		#print("sala_actual: " +str(sala_actual))
		#Recorremos las salas
		for direction in sala_actual.connected_rooms:
			#print("direction: " + str(direction))
			if sala_actual.connected_rooms.get(direction) != null:
				var sala_vecina_coords = sala_actual_coords + direction
				#Si la sala vecina no ha sido visitada
				if not visitados.has(sala_vecina_coords):
					visitados[sala_vecina_coords] = true
					cola.append({"coords": sala_vecina_coords, "distancia": distancia_actual + 1})
	return -1

func encontrar_salas_mas_alejadas() -> Array:
	var max_distancia = -1
	var salas_mas_alejadas = []
	#Iteramos por todas las combinaciones de salas
	var claves_salas = full_map.keys()
	for i in range(claves_salas.size()):
		var sala1_coords = claves_salas[i]
		for j in range(i + 1, claves_salas.size()):
			var sala2_coords = claves_salas[j]
			#Calculamos la distancia mínima entre sala1 y sala2
			var distancia = calcular_distancia(sala1_coords, sala2_coords)
			if (distancia == max_distancia and randi_range(0,1) == 0) or distancia > max_distancia:
				max_distancia = distancia
				salas_mas_alejadas = [sala1_coords, sala2_coords]
	return salas_mas_alejadas
#size = 0 para devolver el mapa limitado (minimapa), que enseña lo cercano
# y size = 1 para devolverlo entero (mapa tecla M), que enseña todo el mapa
func load_map(map, size):
	# Limpiar nodos hijos anteriores, es decir, limpia el mapa
	for i in range(0, map_node.get_child_count()):
		map_node.get_child(i).queue_free()

	#Por cada nodo en el mapa
	for i in map.keys():
		# Crear nodo de habitación
		var room_sprite = Sprite2D.new()
		if size == 0 and !comprueba_sala_en_minimapa(i):
			pass
		else:
			room_sprite.texture = node_sprite
				
			if i == sala_inicio_coords:
				room_sprite.modulate = Color.GREEN
			elif i == sala_final_coords:
				room_sprite.modulate = Color.RED

			room_sprite.z_index = 1
			room_sprite.position = i * 10 - current_coords * 10
			map_node.add_child(room_sprite)  # Añadir el sprite del nodo al mapa
			
			if i == current_coords:
				node_sprite_player.position = map_node.position +  room_sprite.position
				
				#node_sprite_player.show()
				#map_node.add_child(playerSprite)
			
			
			#conexiones de la habitación
			var c_rooms = map.get(i).connected_rooms #mapa [x,y] = z
			

			# Crear conexiones en el eje X
			if c_rooms.get(Vector2(1, 0)) != null && map.values().has(c_rooms.get(Vector2(1, 0)))  && comprueba_sala_en_minimapa(i + Vector2(1,0)):  # Conexión a la derecha
				var right_branch = Sprite2D.new()
				right_branch.texture = branch_sprite
				right_branch.z_index = 0
				right_branch.position = i * 10 + Vector2(5, 0.5)  - current_coords * 10
				map_node.add_child(right_branch)
			
			if c_rooms.get(Vector2(-1, 0)) != null && map.values().has(c_rooms.get(Vector2(-1, 0)))  && comprueba_sala_en_minimapa(i + Vector2(-1,0)):  # Conexión a la izquierda
				var left_branch = Sprite2D.new()
				left_branch.texture = branch_sprite
				left_branch.z_index = 0
				left_branch.position = i * 10 + Vector2(-5, 0.5)   - current_coords * 10# Ajustar la posición
				left_branch.rotation_degrees = 180  # Rotar 180 grados para la conexión izquierda
				map_node.add_child(left_branch)
				# Crear conexiones en el eje Y
			if c_rooms.get(Vector2(0, 1)) != null && map.values().has(c_rooms.get(Vector2(0, 1)))  && comprueba_sala_en_minimapa(i + Vector2(0,1)):  # Conexión hacia abajo
				var down_branch = Sprite2D.new()
				down_branch.texture = branch_sprite
				down_branch.z_index = 0
				down_branch.rotation_degrees = 90
				down_branch.position = i * 10 + Vector2(-0.5, 5)  - current_coords * 10
				map_node.add_child(down_branch)
			if c_rooms.get(Vector2(0, -1)) != null && map.values().has(c_rooms.get(Vector2(0, -1)))  && comprueba_sala_en_minimapa(i + Vector2(0,-1)):  # Conexión hacia arriba
				var up_branch = Sprite2D.new()
				up_branch.texture = branch_sprite
				up_branch.z_index = 0
				up_branch.rotation_degrees = 90
				up_branch.position = i * 10 + Vector2(-0.5, -5)  - current_coords * 10 # Ajustar la posición
				map_node.add_child(up_branch)
				


var is_changing_room = false
#funcion que comprueba que una sala este dentro del margen del minimapa. Se ha establecido en 2, pero puede cambiar
func comprueba_sala_en_minimapa(sala):
	if (sala - current_coords).x > 2 or (sala - current_coords).x < -2:
		return false
	elif (sala - current_coords).y > 2 or (sala - current_coords).y < -2:
		return false
	else:
		return true


func cambiar_sala(direction: Vector2):
	if is_changing_room:
		return
	
	is_changing_room = true
	
	# Posponer el cambio de sala hasta después del procesamiento de físicas
	call_deferred("_realizar_cambio_sala", direction)

func _realizar_cambio_sala(direction: Vector2):
	# 1. Remover la sala actual
	if full_map.has(current_coords):
		full_map[current_coords].hide()
		full_map[current_coords].position += Vector2(400,0)
		
	# 2. Actualizar las coordenadas a la nueva sala
	current_coords += direction
	discovered_map[current_coords] = full_map[current_coords]
	load_map(discovered_map, 1)
	
	# 3. Añadir la nueva sala
	if full_map.has(current_coords):
		
		# 4. Reubicar al jugador dependiendo de la dirección
		if direction == Vector2(1, 0):
			player.position = Vector2(-room_size.x/2 + 10, player.position.y) # Viniendo desde la izquierda
		elif direction == Vector2(-1, 0):
			player.position = Vector2(room_size.x/2 - 10, player.position.y) # Viniendo desde la derecha
		elif direction == Vector2(0, 1):
			player.position = Vector2(player.position.x, -room_size.y/2 + 10) # Viniendo desde arriba
		elif direction == Vector2(0, -1):
			player.position = Vector2(player.position.x, room_size.y/2 - 10) # Viniendo desde abajo
		
		if full_map[current_coords].is_inside_tree():
			full_map[current_coords].show()
			full_map[current_coords].position += Vector2(-400,0)
		else:
			add_child(full_map[current_coords])
			if current_coords != sala_inicio_coords and current_coords != sala_final_coords:
				full_map[current_coords].add_enemies()
		
	await get_tree().create_timer(0.1).timeout
	is_changing_room = false
