extends Control

# Referencia al botón
@onready var button = $Button  # Asegúrate de que el nodo Button esté nombrado correctamente
@onready var map_node
var map_visible = false
var discovered_map = {}
var forest
var current_coords 
var node_sprite = load("res://assets/minimapa/sala.png")
var branch_sprite = load("res://assets/minimapa/pasillo.png")
var node_sprite_player = load("res://assets/minimapa/map_nodes_player.png")
@onready var sprite_animado = $AnimatedSprite2D
@onready var mapaIntento = $Fondo
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
	if !map_visible:
		sprite_animado.hide()
	print(map_visible)

	discovered_map = forest.full_map
	current_coords = forest.current_coords
	
	if map_visible:
		mapaIntento.show()
		mapaIntento.position = get_viewport().get_visible_rect().size/2
		set_sprite_size(mapaIntento, get_viewport().get_visible_rect().size)
		#mapaIntento.sca
		load_map(discovered_map)
		
		get_tree().paused = true  # Pause the game tree

	else:
		mapaIntento.hide()
		get_tree().paused = false  # Unpause the game tree
		for child in map_node.get_children():
			child.queue_free()

func set_sprite_size(sprite: Sprite2D, new_size: Vector2):
	# Obtener el tamaño de la textura original
	var texture_size = sprite.texture.get_size()
	
	# Calcula el factor de escala
	var scale_factor = new_size / texture_size
	
	# Establecer la escala para que el sprite tenga el tamaño deseado
	sprite.scale = scale_factor

# Función para capturar la tecla M y simular el presionado del botón
func _input(event):
	# Si la tecla M ha sido presionada
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		button.emit_signal("pressed")  # Simula que el botón ha sido presionado
	

func load_map(map):
	#Por cada nodo en el mapa
	var max_x = 0
	var max_y = 0
	var min_x = 0
	var min_y = 0
	#las llaves son de la forma x y
	for i in map.keys():
		if max_x < i[0]:
			max_x = i[0]
		if min_x > i[0]:
			min_x = i[0]
		if max_y < i[1]:
			max_y = i[1]
		if min_y > i[1]:
			min_y = i[1]
	print(max_x)
	print(max_y)
	print(min_x)
	print(min_y)
	var prodx = -1
	var prody = -1
	if min_x > 0:
		prodx = 1
	if min_y > 0:
		prody = 1
	var centro = Vector2(int((max_x - min_x * prodx)/2), int((max_y - min_y * prody)/2))
	print(centro)
	
	for i in map.keys():
		# Crear nodo de habitación
		var room_sprite = Sprite2D.new()
		
		"""if i == current_coords:
			room_sprite.texture = node_sprite_player
			room_sprite.scale = Vector2(11.25,11.25)
		else:"""
			
		room_sprite.texture = node_sprite
		room_sprite.scale = Vector2(6, 6)
		room_sprite.z_index = 2
		room_sprite.position = (i - centro) * 120
		map_node.add_child(room_sprite)  # Añadir el sprite del nodo al mapa
		if i == current_coords:
			sprite_animado.scale = Vector2(8, 8)
			sprite_animado.z_index = 4
			sprite_animado.position = map_node.position + room_sprite.position
			sprite_animado.show()
			"""room_sprite.texture = node_sprite_player
			room_sprite.scale = Vector2(11.25,11.25)
			room_sprite.position = i * 120"""
		#conexiones de la habitación
		var c_rooms = map.get(i).connected_rooms
	
		# Crear conexiones en el eje X
		if c_rooms.get(Vector2(1, 0)) != null:  # Conexión a la derecha
			#  && map.values().has(c_rooms.get(Vector2(1, 0)))
			var right_branch = Sprite2D.new()
			right_branch.texture = branch_sprite
			right_branch.scale = Vector2(6,6)
			right_branch.z_index = 3
			right_branch.position = (i - centro  + Vector2(0.5, 0)) * 120 #+ Vector2(5, 0.5)
			map_node.add_child(right_branch)
		
		if c_rooms.get(Vector2(-1, 0)) != null:  # Conexión a la izquierda
			#  && map.values().has(c_rooms.get(Vector2(-1, 0)))
			var left_branch = Sprite2D.new()
			left_branch.texture = branch_sprite
			left_branch.scale = Vector2(6,6)
			left_branch.z_index = 3
			left_branch.position = (i - centro  + Vector2(-0.5, 0)) * 120 #(i - centro) * 120 + Vector2(-5, 0.5)# Ajustar la posición
			left_branch.rotation_degrees = 180  # Rotar 180 grados para la conexión izquierda
			map_node.add_child(left_branch)
			# Crear conexiones en el eje Y
		if c_rooms.get(Vector2(0, 1)) != null:  # Conexión hacia abajo
			#  && map.values().has(c_rooms.get(Vector2(0, 1)))
			var down_branch = Sprite2D.new()
			down_branch.texture = branch_sprite
			down_branch.scale = Vector2(6,6)
			down_branch.z_index = 3
			down_branch.rotation_degrees = 90
			down_branch.position = (i - centro  + Vector2(0, 0.5)) * 120 #(i - centro) * 120 + Vector2(-0.5, 5)
			map_node.add_child(down_branch)
		if c_rooms.get(Vector2(0, -1)) != null:  # Conexión hacia arriba
			#  && map.values().has(c_rooms.get(Vector2(0, -1)))
			var up_branch = Sprite2D.new()
			up_branch.texture = branch_sprite
			up_branch.scale = Vector2(6,6)
			up_branch.z_index = 3
			up_branch.rotation_degrees = 90
			up_branch.position = (i - centro  + Vector2(0, -0.5)) * 120# Ajustar la posición
			map_node.add_child(up_branch)
