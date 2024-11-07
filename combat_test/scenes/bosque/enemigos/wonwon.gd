extends CharacterBody2D

@export var MAX_HEALTH = 3
@export var health = MAX_HEALTH
@export var is_hurt = false
const NORMAL_SPEED = 15
const RUN_SPEED = 25
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 100
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
@onready var screen_size = get_viewport_rect().size
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@onready var healthbar = $Healthbar
@onready var damagebar = $Healthbar/Damagebar
@onready var timer_vida = $Healthbar/Timer
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0
# Movimiento
var near_player = false
var direction_str = "down" # Izquierda derecha arriba abajo, segun a donde mire
var direction_vector
var rotation_vector
const MOVE_CHANCE = 0.7
var move_chance = MOVE_CHANCE
var clockwise
#Ataques
@export var attack_range = 60
var attack_cooldown_time = 1.0  # 1 segundo entre ataques
@onready var attack_cooldown_timer = Timer.new()
@export var is_attacking = false

func _ready():
	if randi_range(0,1) == 0:
		clockwise = true
	else:
		clockwise = false
	position = Vector2(0,0)
	add_child(attack_cooldown_timer)
	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.one_shot = true

func _process(delta: float) -> void:
	# "Timer" para el movimiento random
	if !is_attacking && !is_hurt:
		timer -= delta
		if timer <= 0 and !near_player:
			print(move_chance)
			change_direction()
		set_directionVector_string()
		move(delta) # Nos movemos si se ha pulsado algo
		attack()
		depth_control()
# Literalmente lo mismo que la del caballero pero mas facil. Id a mirar los comentarios en knight.gd
func take_damage(ammount: int, knockback_direction: Vector2, knockback_strength) -> void:
	health -= ammount
	is_hurt = true
	timer_vida.start()
	healthbar.update()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	if health <= 0:
		kill()
	elif is_hurt == false:  # Verifica que el enemigo no esté ya en animación de daño
		print("OUCH")
		$AnimationPlayer.play(str("damage_" + direction_str))
		
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		velocity = knockback_velocity
		move_and_slide()
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		# Reduce el temporizador del retroceso
		knockback_timer -= delta
		
func _on_health_timer_timeout() -> void:
	damagebar.update()
	timer_vida.stop()

# Función de me voy con San Pedro del limo
func kill():
	(str("death_" + direction_str))
	await get_tree().create_timer(0.9).timeout
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	queue_free()
	
func move(delta):
	velocity = Vector2.ZERO
	var player_position = get_player_position()
	if (player_position != null):
		if (position.distance_to(player_position) <= detection_range):
			near_player = true
			move_around_player(player_position, delta, clockwise)
		else:
			move_randomly(delta)
			near_player = false
	else:
		move_randomly(delta)
		near_player = false
	
	if is_attacking == false && is_hurt == false && direction_vector != Vector2(0,0):
		$AnimationPlayer.play(str("normal_" + direction_str))
		$AnimationPlayer.speed_scale = 1
	elif is_attacking == false && is_hurt == false: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
		$AnimationPlayer.play(str("normal_" + direction_str))
		$AnimationPlayer.speed_scale = 0.5
	move_and_slide()

func move_randomly(delta):
	speed = NORMAL_SPEED
	position += direction_vector * speed * delta
	
func move_around_player(player_position: Vector2, delta: float, clockwise: bool = true):
	speed = RUN_SPEED
	var adjustment_vector
	var movement_vector
	direction_vector = (player_position - position).normalized()
	# Toggle direction for clockwise/counterclockwise movement
	if clockwise:
		rotation_vector = Vector2(direction_vector.y, -direction_vector.x)
	else:
		rotation_vector = Vector2(-direction_vector.y, direction_vector.x)
	if (player_position != null):
		var distance = position.distance_to(player_position)
		var factor_ajuste = 2 + abs(distance - 50) / 50
		if (distance < detection_range/2 -1):
			adjustment_vector = -direction_vector * factor_ajuste
		elif (distance > detection_range/2 +1):
			adjustment_vector = direction_vector * factor_ajuste
		else:
			adjustment_vector = Vector2(0,0)
			
	movement_vector = adjustment_vector + rotation_vector
	movement_vector = movement_vector.normalized()
	position += movement_vector * speed * delta
	
func attack():
	var player_position = get_player_position()
	if player_position != null:
		if position.distance_to(player_position) <= attack_range:
			if !is_hurt:
				if !is_attacking and attack_cooldown_timer.is_stopped():
					# Verifica si no está atacando y si ya pasó el cooldown de 1 segundo
					#is_attacking = true
					#TODO animacion ataque
					attack_cooldown_timer.start()

# Código en el script del enemigo

func disparar_proyectil():
	# Carga e instancia el proyectil
	var proyectil = preload("res://scenes/proj_test.tscn").instance()
	# Coloca el proyectil en la posición actual del enemigo
	proyectil.global_position = global_position
	# Agrega el proyectil al nodo padre del enemigo para desvincularlo
	# del movimiento del enemigo (o directamente a la escena principal)
	get_parent().add_child(proyectil)
	# Configura la dirección y velocidad del proyectil
	proyectil.direccion = (get_player_position() - global_position).normalized()
	proyectil.velocidad = 500  # Ajusta la velocidad como necesites


func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 15

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
	
func set_directionVector_string():
	var x = direction_vector.x
	var y = direction_vector.y
	if y < - abs(x):
		direction_str = "up"
	elif x > abs(y):
		direction_str = "right"
	elif y > abs(x):
		direction_str = "down"
	elif x < abs(y):
		direction_str = "left"
	#else:
		#print("Estoy quieto")
	
func change_direction():
	if randf_range(0, 1) < move_chance:
		move_chance = move_chance * MOVE_CHANCE
		# Genera un nuevo vector aleatorio con valores entre -1 y 1
		direction_vector = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	else:
		move_chance = MOVE_CHANCE
		direction_vector = Vector2(0, 0)
	# Reinicia el timer
	timer = direction_change_interval

func status():
	print("...............")
	print("is_attacking: ")
	print(is_attacking)
	print("is_hurt: ")
	print(is_hurt)

func _on_wall_detection_body_entered(body: Node2D) -> void:
	if clockwise:
		clockwise = false
	else:
		clockwise = true
