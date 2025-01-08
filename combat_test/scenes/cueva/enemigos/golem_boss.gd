extends CharacterBody2D

@export var MAX_HEALTH = 15
@export var health = MAX_HEALTH
@export var is_hurt = false
var direction_str = "down" # Izquierda derecha arriba abajo, segun a donde mire
var screen_size

const NORMAL_SPEED = 20
const RUN_SPEED = 35
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado

#Sonidos
@onready var hurt_VFX = $hurt_vfx
@onready var healthbar = $CanvasLayer/Healthbar
@onready var damagebar = $CanvasLayer/Healthbar/Damagebar
@onready var timer_vida = $CanvasLayer/Healthbar/Timer
@onready var rayo = $RayoLaser
@onready var proyectil_scene = preload("res://scenes/cueva/enemigos/projectileGolem.tscn")
@onready var attack_timer = $AttackTimer
var can_attack = false
var is_attacking = false
var attack_cooldown_time = 1.0  # segundos entre ataques
var is_dying = false
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0
#Slimes invocados
var slime_scene = preload("res://scenes/cueva/enemigos/golem_boss.tscn")

var segunda_fase_iniciada = false
var temp = true
var rayando = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	position = Vector2(0,0)
	attack_timer.wait_time = attack_cooldown_time
	attack_timer.start()
	$LaserTimer.stop()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_hurt == false and is_dying == false and rayando == false: # Mientras no esté siendo herido, el limo se mueve normal
		set_directionVector_string()
		if !is_attacking:
			move(delta)
	depth_control()
	
	# Actualiza el timer para cambiar la dirección
	timer -= delta
	if timer <= 0:
		change_direction()
	if health * 2 <= MAX_HEALTH && !segunda_fase_iniciada:
		segunda_fase_iniciada = true
		
	if segunda_fase_iniciada == true and temp == true:
		$LaserTimer.start()
		temp = false
	
	

func _on_laser_timer_timeout():
	rayando = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("laserRight")
	await rayo.ataqueMomento()
	$LaserTimer.start()
	print("laser activado")
	rayando = false
	
	
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
	#else:
		#print("Estoy quieto")
# Función para cambiar la dirección aleatoriamente
func change_direction():
	# Genera un nuevo vector aleatorio con valores entre -1 y 1
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Reinicia el timer
	timer = direction_change_interval
	
# Literalmente lo mismo que la del caballero pero mas facil. Id a mirar los comentarios en knight.gd
func take_damage(ammount: int, knockback_direction: Vector2, knockback_strength) -> void:
	hurt_VFX.play()
	health -= ammount
	timer_vida.start()
	healthbar.update()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	if health <= 0:
		stop_timers()
		kill()
	elif is_hurt == false:  # Verifica que el enemigo no esté ya en animación de daño
		#$AnimationPlayer.play("damage")
		pass
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		velocity = knockback_velocity
		move_and_slide()
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		# Reduce el temporizador del retroceso
		knockback_timer -= delta
		
func _on_timer_timeout() -> void:
	damagebar.update()
	timer_vida.stop()

func stop_timers() -> void:
	$AttackTimer.stop

# Función de me voy con San Pedro del limo
func kill():
	is_dying = true
	$AnimationPlayer.stop()
	$AnimationPlayer.play("c_murio")
	await get_tree().create_timer(5.0).timeout
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	queue_free()
	
func move(delta):
	velocity = Vector2.ZERO
	var player_position = get_player_position()
	if (player_position != null):
		move_towards_player(player_position, delta)
	
	var dir = direction_str
	
	#temporalFixWhileTheresNoDownAndUp
	if direction_str == "Down" or direction_str == "Up"  or direction_str == "down":
		dir = "Left"
	
	$AnimationPlayer.play(str("run" + dir))
	
	move_and_slide()

func move_randomly(delta):
	speed = NORMAL_SPEED
	$GolemSprite.speed_scale = 1
	position += direction * speed * delta
	move_and_slide()
	
func move_towards_player(player_position: Vector2, delta: float):
	speed = NORMAL_SPEED
	#$GolemSprite.speed_scale = 2
	
	direction = (player_position - position).normalized()
	position += direction * speed * delta
	move_and_slide()
	
func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 10

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


func _on_attack_timer_timeout() -> void:

	if is_attacking or can_attack:
		pass
	elif rayando:
		attack_timer.start()
		is_attacking = false
	elif is_dying:
		return
	else:
		is_attacking = true
		var dir = direction_str
		if get_player_position().distance_to(position) < 40:
			can_attack = true
			punch(dir)
		else:
			if dir == "Right":
				$AnimationPlayer.play("disparoRight")
			else:
				$AnimationPlayer.play("disparoLeft")
			
			await get_tree().create_timer(1.35).timeout
			
			can_attack = true
			shoot(dir)

func punch(dir):
	if can_attack and is_dying == false and rayando == false:
		can_attack = false
		var animacion = dir
		#apaño temporal

		if animacion == "Down" or animacion == "Up":
			animacion = "Left"
				
		$AnimationPlayer.stop()
		$AnimationPlayer.play(str("punho") + animacion)
		await get_tree().create_timer(3).timeout
	is_attacking = false
	attack_timer.start()
	print("Fino")

func shoot(dir):
	if can_attack and is_dying == false and rayando == false:
		can_attack = false
		
		var proyectil = proyectil_scene.instantiate()
		proyectil.golem = self
		proyectil.position = position
		get_parent().add_child(proyectil)
		await get_tree().create_timer(0.8).timeout
		var animacion = dir
		
		#apaño temporal
		if animacion == "Down" or animacion == "Up":
			animacion = "Left"
			
		
		for i in range(2):
			if is_dying == true or rayando == true:
				attack_timer.start()
				is_attacking = false
				return
				
			$AnimationPlayer.stop()
			$AnimationPlayer.play(str("regeneraTiro") + animacion)
			proyectil = proyectil_scene.instantiate()
			proyectil.golem = self
			proyectil.position = position
			get_parent().add_child(proyectil)
			await get_tree().create_timer(0.8).timeout
			

	is_attacking = false
	attack_timer.start()
		
