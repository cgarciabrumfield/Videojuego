extends Area2D
class_name Bullet

@export var speed = 100
var direction
@onready var screen_size = get_viewport_rect().size
var wonwon
var was_parried = false

func _ready():
	direction = direction_to_player()
	
func _process(delta: float) -> void:
	global_position = global_position + direction * delta * speed
	depth_control()
	
func direction_to_player():
	var vector = get_player_position() - position
	return vector.normalized()

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

func _on_body_entered(hitbox) -> void:
	if was_parried:
		print(hitbox.owner)
		print(hitbox)
		return
	queue_free()

func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	var normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 15

func get_parried():
	was_parried = true
	$Hitbox.damage = wonwon.MAX_HEALTH
	direction = (wonwon.position - position).normalized()
	speed = speed * 2
