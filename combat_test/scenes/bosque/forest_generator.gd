extends Node2D

var full_map = {}
var discovered_map = {}
var node_sprite = load("res://assets/minimapa/map_nodes1.png")
var branch_sprite = load("res://assets/minimapa/map_nodes2.png")
var node_sprite_player = load("res://assets/minimapa/map_nodes_player.png")

var room = preload("res://scenes/forest_room.tscn")
@onready var map_node = $MapNode
@onready var player = $Player
@onready var camera = $Camera2D
const CAMERA_ZOOM = Vector2(6, 5.65)
var current_coords
var zoomed_viewport_size

func _ready():
	camera.zoom = CAMERA_ZOOM
	zoomed_viewport_size = get_viewport_rect().size / CAMERA_ZOOM
	full_map = generate(randi_range(-1000, 1000))
	current_coords = Vector2(0,0)
	discovered_map[current_coords] = full_map[current_coords]
	add_child(full_map[current_coords])
	load_map(discovered_map)

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
		print(sed)
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

func load_map(map):
	# Limpiar nodos hijos anteriores
	for i in range(0, map_node.get_child_count()):
		map_node.get_child(i).queue_free()
		# Añadir nodos del mapa
	for i in map.keys():
		# Crear nodo de habitación
		var room_sprite = Sprite2D.new()
		if i == current_coords:
			room_sprite.texture = node_sprite_player
		else:
			room_sprite.texture = node_sprite
		room_sprite.z_index = 1
		room_sprite.position = i * 10
		map_node.add_child(room_sprite)  # Añadir el sprite del nodo al mapa
		#conexiones de la habitación
		var c_rooms = map.get(i).connected_rooms
		# Crear conexiones en el eje X
		if c_rooms.get(Vector2(1, 0)) != null && map.values().has(c_rooms.get(Vector2(1, 0))):  # Conexión a la derecha
			var right_branch = Sprite2D.new()
			right_branch.texture = branch_sprite
			right_branch.z_index = 0
			right_branch.position = i * 10 + Vector2(5, 0.5)
			map_node.add_child(right_branch)
		
		if c_rooms.get(Vector2(-1, 0)) != null && map.values().has(c_rooms.get(Vector2(-1, 0))):  # Conexión a la izquierda
			var left_branch = Sprite2D.new()
			left_branch.texture = branch_sprite
			left_branch.z_index = 0
			left_branch.position = i * 10 + Vector2(-5, 0.5)  # Ajustar la posición
			left_branch.rotation_degrees = 180  # Rotar 180 grados para la conexión izquierda
			map_node.add_child(left_branch)
			# Crear conexiones en el eje Y
		if c_rooms.get(Vector2(0, 1)) != null && map.values().has(c_rooms.get(Vector2(0, 1))):  # Conexión hacia abajo
			var down_branch = Sprite2D.new()
			down_branch.texture = branch_sprite
			down_branch.z_index = 0
			down_branch.rotation_degrees = 90
			down_branch.position = i * 10 + Vector2(-0.5, 5)
			map_node.add_child(down_branch)
		if c_rooms.get(Vector2(0, -1)) != null && map.values().has(c_rooms.get(Vector2(0, -1))):  # Conexión hacia arriba
			var up_branch = Sprite2D.new()
			up_branch.texture = branch_sprite
			up_branch.z_index = 0
			up_branch.rotation_degrees = 90
			up_branch.position = i * 10 + Vector2(-0.5, -5)  # Ajustar la posición
			map_node.add_child(up_branch)
			
			
var is_changing_room = false

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
	load_map(discovered_map)
	
	# 3. Añadir la nueva sala
	if full_map.has(current_coords):
		
		# 4. Reubicar al jugador dependiendo de la dirección
		if direction == Vector2(1, 0):
			player.position = Vector2(-zoomed_viewport_size.x/2 + 10, player.position.y) # Viniendo desde la izquierda
		elif direction == Vector2(-1, 0):
			player.position = Vector2(zoomed_viewport_size.x/2 - 10, player.position.y) # Viniendo desde la derecha
		elif direction == Vector2(0, 1):
			player.position = Vector2(player.position.x, -zoomed_viewport_size.y/2 + 10) # Viniendo desde arriba
		elif direction == Vector2(0, -1):
			player.position = Vector2(player.position.x, zoomed_viewport_size.y/2 - 10) # Viniendo desde abajo
		print(player.position)
		
		if full_map[current_coords].is_inside_tree():
			full_map[current_coords].show()
			full_map[current_coords].position += Vector2(-400,0)
		else:
			add_child(full_map[current_coords])
		
	await get_tree().create_timer(0.1).timeout
	is_changing_room = false
