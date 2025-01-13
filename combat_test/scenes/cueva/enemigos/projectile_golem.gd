extends Area2D
#class_name Bullet

@export var speed = 100
var direction
@onready var screen_size = get_viewport_rect().size
var golem
var was_parried = false
var direction_str = ""
@onready var sprite = $Sprite2D
@onready var shadow = $Shadow
@onready var collisionBox = $CollisionBox
@onready var hitbox = $Hitbox
var dirPrev = "Right"
var colision
func _ready():
	colision = hitbox.get_child(0)
	direction = direction_to_player()
	set_directionVector_string()
	var ruta = "res://assets/sprites/enemies/ataques_golem/tiro"+direction_str+".png"
	sprite.texture = load(ruta)

	cambiarPosicionesSegunDireccion()
	
	
func _process(delta: float) -> void:
	global_position = global_position + direction * delta * speed
	depth_control()
	
func direction_to_player():
	var vector = get_player_position() - position
	vector.y = vector.y - colision.position.y
	return vector.normalized()

func set_directionVector_string():
	var x = direction.x
	var y = direction.y
	if y < - abs(x):
		direction_str = "Up"
	elif x > abs(y):
		direction_str = "Right"
	elif y > abs(x):
		direction_str = "Down"
	elif x < abs(y):
		direction_str = "Left"

	if direction_str == "Up" or direction_str == "Down":
		direction_str = "Left"
		
func cambiarPosicionesSegunDireccion():
	if dirPrev != direction_str:
		if (direction_str == "Left" and dirPrev == "Right") or (direction_str == "Right" and dirPrev == "Left"):
			shadow.position.x = shadow.position.x * -1
			collisionBox.position.x = collisionBox.position.x * -1
			colision.position.x = colision.position.x * -1
		
			
	dirPrev = direction_str
		
func get_player_position():
	return _find_player(get_tree().get_root())

func _find_player(node):
	if node.name == "Player":
		return node.position
		
	for child in node.get_children():
		var position_jugador = _find_player(child)
		if position_jugador != null:
			return position_jugador
	return null

func _on_body_entered(itbox) -> void:
	if was_parried:
		print(itbox.owner)
		print(itbox)
		return
	queue_free()

func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	var normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 15

func get_parried():
	was_parried = true
	$Hitbox.damage = 2
	direction = (golem.position - position).normalized()
	speed = speed * 2
