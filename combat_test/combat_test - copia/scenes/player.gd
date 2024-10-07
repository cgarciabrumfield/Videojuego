class_name Player
extends CharacterBody2D

@export var speed = 150 # How fast the player will move (pixels/sec).
@export var life = 10
var screen_size # Size of the game window.
var direction # Izquierda derecha arriba abajo, segun a donde mire
@export var is_attacking = false # Si está atacando bloquea las demás acciones y entradas
@export var is_blocking = false # Si está bloqueando bloquea las demás acciones y entradas
@export var is_parrying = false
@export var is_inmune = false
@export var is_hurt = false # Al recibir daño se bloquean las demas acciones y entradas
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@export var inmune_time = 1.5
var inmune_timer = Timer.new()
# Parry timer
var parry_timer = Timer.new()
# Variable para el temporizador de enfriamiento
var attack_timer = Timer.new()
var second_attack_queued = false
@onready var slash_VFX = $VFXs/Sword_VFX
@onready var hurt_VFX = $VFXs/hurt_VFX
@onready var walk_VFX = $VFXs/walk_grass_VFX
@onready var block_VFX = $VFXs/block_VFX
@onready var parry_VFX = $VFXs/parry_VFX

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size #Vector de resolución de pantalla
	direction = str("down") # El personaje empieza mirando hacia abajo
	position = screen_size / 2 # situamos al personaje en el centro de la pantalla
	$Sword1/Hitbox_Sword1.disabled = true # La hitbox (espada) empieza emvainadas
	$Sword2/Hitbox_Sword2.disabled = true
	# Configura y agrega el temporizador de parry al nodo actual
	parry_timer.wait_time = 0.1
	add_child(parry_timer)
	parry_timer.connect("timeout", self._on_parry_timer_timeout)
	# Configura y agrega el temporizador de inmunidad al nodo actual
	inmune_timer.wait_time = $AnimationPlayer.get_animation("damage_down").length + 0.5
	add_child(inmune_timer)
	inmune_timer.connect("timeout", self._on_inmune_timer_timeout)
	# Configura y agrega el temporizador de ataque al nodo actual
	# El tiempo de espera del input del 2º ataque es la duracion del primer ataque
	attack_timer.wait_time = $AnimationPlayer.get_animation("attack_down").length
	attack_timer.one_shot = true  # Solo se ejecuta una vez
	add_child(attack_timer)
	attack_timer.connect("timeout", self._on_attack_timer_timeout)
	$Parry_effect_sprite.z_index = RenderingServer.CANVAS_ITEM_Z_MAX

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#var current_animation = $AnimationPlayer.current_animation  # Obtiene la animación actual
	#print("Animación en curso: ", current_animation)
	move() # Nos movemos si se ha pulsado algo
	if Input.is_action_just_pressed("attack"):	
		attack()
	if Input.is_action_just_pressed("block"):	
		block() # Bloqueamos si procede
	depth_control()

func move(): # Función que mueve al personaje
	velocity = Vector2.ZERO #Vector de movimiento del jugador
	if !is_attacking && !is_blocking && !is_hurt && !is_parrying:
		if Input.is_action_pressed("right"):
			velocity.x += 1
			# Actualizamos la dirección en la que mira el personaje, para todas las animaciones
			direction = "right"
		if Input.is_action_pressed("left"):
			velocity.x -= 1
			direction = "left"
		if Input.is_action_pressed("down"):
			velocity.y += 1
			direction = "down"
		if Input.is_action_pressed("up"):
			velocity.y -= 1
			direction = "up"
		# Si nos estamos moviendo, y no hemos sido heridos, animación de correr. 
		if !is_attacking && !is_blocking && !is_hurt && !is_parrying && velocity.length() > 0:
			velocity = velocity.normalized() * speed
			$AnimationPlayer.play(str("run_" + direction))
		elif !is_attacking && !is_blocking && !is_hurt && !is_parrying: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
			$AnimationPlayer.play(str("iddle_" + direction))
		# Actualizamos la posición según el vector de dirección y delta (constancia fps)
		#position += velocity * delta
		move_and_slide()
		#position = position.clamp(Vector2.ZERO, screen_size)
# Función de ataque. Si ha sido pulsado y no estamos bloqueando ni reciviendo daño, tiene lugar	
func attack():
	if !is_blocking && !is_hurt && !is_parrying:
		if !is_attacking:
			slash_VFX.play()
			$AnimationPlayer.play(str("attack_" + direction))
			attack_timer.start()  # Inicia el temporizador
		elif attack_timer.time_left > 0 && !second_attack_queued:
			# Si la animación de ataque 1 está en curso y el temporizador no ha terminado
			second_attack_queued = true

# Callback cuando la animación de ataque termina
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack_"):
		if second_attack_queued:
			$AnimationPlayer.play(str("attack_" + direction))
			$AnimationPlayer.stop(false)
			slash_VFX.play()
			$AnimationPlayer.play(str("attack_" + direction + "_2"))  # Reproducir la segunda animación de ataque
			second_attack_queued = false

func _on_attack_timer_timeout():
	# Cuando el temporizador se agota, resetea la cola de ataque
	second_attack_queued = false


#Función de bloqueo. Funciona de manera practicamente idéntica a ataque, aunque la hitbox y su uso no está implementado
func block():
	if !is_attacking && !is_blocking && !is_hurt && !is_parrying:
		print("Entrada")
		parry_timer.start()
		$AnimationPlayer.play(str("shield_up_frame_" + direction))
		
func _input(event):
	if event.is_action_released("block"):
		if parry_timer.time_left > 0:
			print("Parry")
			status()
			$AnimationPlayer.play(str("parry_") + direction)
		else:
			$AnimationPlayer.play(str("stop_block_") + direction)
			print("Stop block")
			
func _on_parry_timer_timeout():
	parry_timer.stop()
	if Input.is_action_pressed("block"):
		$AnimationPlayer.play(str("block_") + direction)
		print("block")

# Función de recivir daño. Solo se activa cuando la hurtbox del personaje detecte una hitbox 
# con un valor de daño asociado que llamaremos amount		
func take_damage(damage: int, knockback_direction: Vector2, knockback_strength: int,
 attacker: Node2D, can_be_parried: bool, can_be_blocked: bool) -> void:
	if is_inmune:
		return
	if is_parrying and can_be_parried:
		try_parry(attacker)
		return
	if is_blocking and can_be_blocked:
		if check_blocking(attacker): # Devuelve true si ha bloqueado correctamente
			return
	is_blocking = false
	is_parrying = false
	is_inmune = true
	is_attacking = false
	hurt_VFX.play()
	life -= damage
	if life <= 0:
		kill()
	elif not is_hurt:
		is_hurt = true
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration
		inmune_timer.start()
		$AnimationPlayer.play(str("damage_" + direction))
		await get_tree().create_timer(0.6).timeout
		is_hurt = false

func _on_inmune_timer_timeout():
	is_inmune = false
		
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		velocity = knockback_velocity
		move_and_slide()
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		# Reduce el temporizador del retroceso
		knockback_timer -= delta

func check_blocking(attacker: Node2D):
	var attacker_direction_vector = (attacker.position - position).normalized()
	var x = attacker_direction_vector.x
	var y = attacker_direction_vector.y
	var attacker_position_str
	if y < - abs(x):
		attacker_position_str = "up"
	elif x > abs(y):
		attacker_position_str = "right"
	elif y > abs(x):
		attacker_position_str = "down"
	elif x < abs(y):
		attacker_position_str = "left"
	if attacker_position_str == direction:
		block_VFX.play()
		return true
	return false

func try_parry(attacker: Node2D):
	var attacker_direction_vector = (attacker.position - position).normalized()
	var x = attacker_direction_vector.x
	var y = attacker_direction_vector.y
	var attacker_position_str
	if y < - abs(x):
		attacker_position_str = "up"
	elif x > abs(y):
		attacker_position_str = "right"
	elif y > abs(x):
		attacker_position_str = "down"
	elif x < abs(y):
		attacker_position_str = "left"
	if attacker_position_str == direction:
		is_attacking = false
		is_blocking = false
		is_parrying = false
		parry_VFX.play()
		$Animation_parry_effect.play(str("parry_" + direction))
		attacker.get_parried()

# Animación que se reproduce al morir
func kill():
	hurt_VFX.pitch_scale = 0.8
	hurt_VFX.play()
	is_hurt = true # Ponemos el estado de ser dañado simplemente para bloquear otras acciones
	speed = 0; # Ya no nos movemos mas, por si acaso, aunque creo que no hace falta
	$AnimationPlayer.play(str("death_" + direction))  #Animación de el cuerpo me pide tierra
	await get_tree().create_timer(0.8).timeout  # Esperamos a que termine y eliminamos el pj
	get_tree().reload_current_scene() #TODO realmente aquí iria la pantalla de gameover o la cinematica de revivir, etc
	
func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	# Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	z_index = normalized_Y_pos * 90 + 10
	
func status():
	print("...............")
	print("is_attacking: ")
	print(is_attacking)
	print("is_blocking: ")
	print(is_blocking)
	print("is_parrying: ")
	print(is_parrying)
	print("is_hurt: ")
	print(is_hurt)
	print("is_inmune: ")
	print(is_inmune)
