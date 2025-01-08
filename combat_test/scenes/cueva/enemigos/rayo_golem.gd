extends Node2D

@onready var cabeza = $cabeza
@onready var laser = $laser

@onready var cabesa = $cabezaArea
@onready var cabezaColision = cabesa.get_node("CollisionShape2D")

@onready var laser2 = $laser2
@onready var laserArea = laser2.get_node("CollisionShape2D")

var radio
var angulo
var velocidad_rotacion
var salirDeCirculo
var laser_offset # Offset inicial entre laser y laserArea
var longitud
var numHijos = 8
var disparos = false
var rayando = false

var layer 
var mask

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	layer = laser2.collision_layer
	mask = laser2.collision_mask
	
	laser2.collision_layer = 1
	laser2.collision_mask = 1
	
	angulo = (get_player_position() - cabezaColision.position).angle()
	radio = cabezaColision.shape.radius # el radio es 10

	salirDeCirculo = laserArea.position.distance_to(cabezaColision.position)

	velocidad_rotacion = 1
	laser_offset = laser.position.distance_to(laserArea.position)
	for i in range(numHijos):
		var hijo = laserArea.duplicate()
		laser2.add_child(hijo)
		
	for i in range(numHijos):
		var hijo = laser.duplicate()
		for son in hijo.get_children():
			hijo.remove_child(son)
		laser.add_child(hijo)
	longitud = laserArea.shape.extents * 2 #+ Vector2(-1,0)

	
func _process(_delta):

	if angulo > PI:
		angulo -=TAU
	if angulo < -PI:
		angulo += TAU
	
	var target_angle = (get_player_position_v2() - cabezaColision.position).angle()
	# Diferencia entre el ángulo actual y el objetivo
	var angle_diff = target_angle - angulo

	if angle_diff > PI:
		angle_diff -= TAU  # -2 * PI para acortar el ángulo
	elif angle_diff < -PI:
		angle_diff += TAU  # 2 * PI para acortar el ángulo
		
		

	if abs(angle_diff) > 0.01:
		if angle_diff > 0:
			angulo += 0.01
		else:
			angulo -= 0.01
	else:
		angulo = target_angle

	# Calcular la nueva posición del laser con base en el ángulo
	laser2.position = cabezaColision.position + Vector2(cos(angulo), sin(angulo)) * salirDeCirculo
	laser2.rotation = angulo + PI


	laser.rotation = angulo + PI
	laser.position = laser2.position + Vector2(cos(angulo), sin(angulo)) * laser_offset - Vector2(cos(angulo) - sin(angulo), sin(angulo) + cos(angulo)) * radio * 1.7
	
	var desplazamiento = Vector2(1, 0) * (-longitud)
	var i = 0
	for hijo in laser2.get_children():
		hijo.position = desplazamiento * i - Vector2(-1,0) * i
		
		i += 1
		if i > numHijos:
			break
	
	if rayando:
		if cabeza.frame == 9:
			laser.show()
			laser2.collision_layer = layer
			laser2.collision_mask = mask
			# Actualiza la colisión de los hijos de laserArea
			laser.play("default")
			disparos = true
		elif cabeza.frame == 0:
			laser2.collision_layer = 1
			laser2.collision_mask = 1
			laser.hide()		
			disparos = false
	else:
		laser.hide()		
		disparos = false
	i = 1
	
	for hijo in laser.get_children():
		hijo.position = desplazamiento * i - Vector2(-1,0) * i

		i += 1
		if disparos:
			hijo.show()
			hijo.play("default")
			hijo.frame = laser.frame
		elif !disparos:
			hijo.hide()		
		if i > numHijos:
			break

	
func get_player_position():
	return _find_player(get_tree().get_root())
	
func get_player_position_v2():
	return _find_player_v2(get_tree().get_root())
	

func _find_player(node):
	if node.name == "Player":
		return node.position
		
	for child in node.get_children():
		var position_jugador = _find_player(child)
		if position_jugador != null:
			return position_jugador
	return null
	
func _find_player_v2(node):
	if node.name == "Player":
		return to_local(node.get_child("Hurtbox").global_position)
		
	for child in node.get_children():
		var position_jugador = _find_player(child)
		if position_jugador != null:
			return position_jugador
	return null
	

func ataqueMomento():
	rayando = true
	cabeza.show()
	cabeza.play("default")
	await cabeza.animation_finished
	cabeza.hide()
	laser.hide()
	rayando = false
	return
