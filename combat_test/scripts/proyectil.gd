extends Area2D
class_name Bullet

@export var speed = 100
var direction
@onready var screen_size = get_viewport_rect().size
var wonwon
var was_parried = false
#Tiempo de vida del proyectil. 0 si no muere por tiempo
@export var LIFE_TIME = 0
var timer = 0

func _ready():
	direction = direction_to_player()
	if $Sprite2D is AnimatedSprite2D:
		$Sprite2D.play()
	
func _process(delta: float) -> void:
	global_position = global_position + direction * delta * speed
	depth_control()
	if LIFE_TIME != 0:
		timer += delta
		if timer >= LIFE_TIME:
			queue_free()
	
func direction_to_player():
	var vector = Globals.get_player_position(self) - position
	return vector.normalized()

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
