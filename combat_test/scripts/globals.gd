extends Node

var room_size = Vector2(320, 191.15)
const CAMERA_ZOOM = Vector2(5, 5)
	
func get_random_direction(position:Vector2, move_chance_const:float, move_anyways: bool = false) -> Vector2:
	var x_value
	var y_value
	var move_chance = move_chance_const
	var direction_vector
	if (randf_range(0, 1) < move_chance) or move_anyways:
		move_chance = move_chance * move_chance_const
		# Genera un nuevo vector aleatorio con valores entre -1 y 1
		var x_max_value = Globals.room_size.x / 2
		if (abs(position.x) > x_max_value * 0.85):
			x_value = randf_range(-x_max_value - position.x, x_max_value - position.x)
		else:
			x_value = randf_range(-x_max_value, x_max_value)
		var y_max_value = Globals.room_size.y / 2
		if (abs(position.y) > y_max_value * 0.85):
			y_value = randf_range(-y_max_value - position.y, y_max_value - position.y)
		else:
			y_value = randf_range(-y_max_value, y_max_value)
		direction_vector = Vector2(x_value, y_value).normalized()
	else:
		move_chance = move_chance_const
		direction_vector = Vector2.ZERO
	return direction_vector
	
func depth_control(position:Vector2, screen_size, offset:float = 0.0):
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	var normalized_Y_pos = position.y / screen_size.y
	# Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	return normalized_Y_pos * 90 + 11 + offset

func get_player_position(node: Node):
	return _find_player(node.get_tree().get_root())

func _find_player(node):
	if node.name == "Player":
		return node.position
		
	for child in node.get_children():
		var position_jugador = _find_player(child)
		if position_jugador != null:
			return position_jugador
	return null
	
func set_directionVector_string(direction_vector:Vector2) -> String:
	var x = direction_vector.x
	var y = direction_vector.y
	if y < - abs(x):
		return "up"
	elif x > abs(y):
		return "right"
	elif y > abs(x):
		return "down"
	elif x < abs(y):
		return "left"
	else:
		return "down"

func find_valid_spawn_position(initial_position: Vector2, mob: Node2D) -> Vector2:
	const MAX_ATTEMPTS = 5      # Intentos por distancia
	const INCREMENT = 5         # Incremento de distancia
	const COLLISION_LAYER = 48  # Máscara de capa 5 + 6
	var space_state = mob.get_world_2d().direct_space_state
	var distance = INCREMENT
	while true:
		for i in range(MAX_ATTEMPTS):
			# Generar un punto aleatorio en un círculo alrededor de la posición inicial
			var angle = randf() * TAU
			var offset = Vector2(cos(angle), sin(angle)) * distance
			var test_position = initial_position + offset
			# Configurar los parámetros de la consulta
			var query = PhysicsPointQueryParameters2D.new()
			query.position = test_position
			query.collision_mask = COLLISION_LAYER
			# Verificar si hay colisión en el punto
			var results = space_state.intersect_point(query, 1)  # Máximo 1 resultado
			if not results:
				return test_position  # Retornar posición válida
			# Incrementar la distancia si no se encontró un lugar válido
		distance += INCREMENT
		print("Incrementando distancia a:", distance)
	return initial_position
