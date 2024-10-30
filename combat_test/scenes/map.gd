extends Control

# Referencia al botón
@onready var button = $Button  # Asegúrate de que el nodo Button esté nombrado correctamente
@onready var map_node
var map_visible = false
var discovered_map = {}
var forest
var current_coords 
var node_sprite = load("res://assets/minimapa/map_nodes1.png")
var branch_sprite = load("res://assets/minimapa/map_nodes2.png")
var node_sprite_player = load("res://assets/minimapa/map_nodes_player.png")

@onready var ui_layer = self.get_parent()

func _ready():
	# Connect the button's signal using Callable instead of a string
	button.connect("pressed", Callable(self, "_on_Button_pressed"))
	forest = self.get_parent().get_parent().get_node("forest")
	map_node = self.get_node("Mapa")
	map_node.position = Vector2(1920 / 2, 1080 / 2)

	if forest == null:
		print("Forest node not found")


func _on_Button_pressed():
	map_visible = !map_visible
	print(map_visible)

	discovered_map = forest.full_map
	current_coords = forest.current_coords
	
	if map_visible:
		load_map(discovered_map)
		get_tree().paused = true  # Pause the game tree
	else:
		get_tree().paused = false  # Unpause the game tree
		for child in map_node.get_children():
			child.queue_free()

		

# Función para capturar la tecla M y simular el presionado del botón
func _input(event):
	# Si la tecla M ha sido presionada
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		button.emit_signal("pressed")  # Simula que el botón ha sido presionado
	

func load_map(map):
	#Por cada nodo en el mapa
	for i in map.keys():
		# Crear nodo de habitación
		var room_sprite = Sprite2D.new()
		
		if i == current_coords:
			room_sprite.texture = node_sprite_player
		else:
			room_sprite.texture = node_sprite
		room_sprite.scale = Vector2(5,5)
		room_sprite.z_index = 2
		room_sprite.position = i * 50
		map_node.add_child(room_sprite)  # Añadir el sprite del nodo al mapa
		#conexiones de la habitación
		var c_rooms = map.get(i).connected_rooms

		# Crear conexiones en el eje X
		if c_rooms.get(Vector2(1, 0)) != null && map.values().has(c_rooms.get(Vector2(1, 0))):  # Conexión a la derecha
			var right_branch = Sprite2D.new()
			right_branch.texture = branch_sprite
			right_branch.scale = Vector2(5,5)
			right_branch.z_index = 0
			right_branch.position = i * 50 + Vector2(5, 0.5)
			map_node.add_child(right_branch)
		
		if c_rooms.get(Vector2(-1, 0)) != null && map.values().has(c_rooms.get(Vector2(-1, 0))):  # Conexión a la izquierda
			var left_branch = Sprite2D.new()
			left_branch.texture = branch_sprite
			left_branch.scale = Vector2(5,5)
			left_branch.z_index = 0
			left_branch.position = i * 50 + Vector2(-5, 0.5)# Ajustar la posición
			left_branch.rotation_degrees = 180  # Rotar 180 grados para la conexión izquierda
			map_node.add_child(left_branch)
			# Crear conexiones en el eje Y
		if c_rooms.get(Vector2(0, 1)) != null && map.values().has(c_rooms.get(Vector2(0, 1))):  # Conexión hacia abajo
			var down_branch = Sprite2D.new()
			down_branch.texture = branch_sprite
			down_branch.scale = Vector2(5,5)
			down_branch.z_index = 0
			down_branch.rotation_degrees = 90
			down_branch.position = i * 50 + Vector2(-0.5, 5)
			map_node.add_child(down_branch)
		if c_rooms.get(Vector2(0, -1)) != null && map.values().has(c_rooms.get(Vector2(0, -1))):  # Conexión hacia arriba
			var up_branch = Sprite2D.new()
			up_branch.texture = branch_sprite
			up_branch.scale = Vector2(5,5)
			up_branch.z_index = 0
			up_branch.rotation_degrees = 90
			up_branch.position = i * 50 + Vector2(-0.5, -5)# Ajustar la posición
			map_node.add_child(up_branch)
		
