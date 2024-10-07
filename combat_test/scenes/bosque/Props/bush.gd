extends StaticBody2D
var screen_size
var normalized_Y_pos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	depth_control()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	# Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	self.z_index = normalized_Y_pos * 90 + 10
