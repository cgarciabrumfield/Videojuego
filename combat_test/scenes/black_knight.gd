extends Area2D

@export var life = 3
var screen_size # Size of the game window.
var direction_str = "down" # Izquierda derecha arriba abajo, segun a donde mire
var direction_vector
@export var is_attacking = false # Si está atacando bloquea las demás acciones y entradas
@export var is_blocking = false # Si está bloqueando bloquea las demás acciones y entradas
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@export var is_hurt = false # Al recibir daño se bloquean las demas acciones y entradas
@export var was_parried = false
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
# Variable para el temporizador de enfriamiento
var attack_timer = Timer
var second_attack_queued = false
@onready var slash_VFX = $VFXs/Sword_VFX
@onready var hurt_VFX = $VFXs/hurt_VFX
@onready var walk_VFX = $VFXs/walk_stone_VFX
@onready var block_VFX = $VFXs/block_VFX

const MOVE_CHANCE = 0.7
var move_chance = MOVE_CHANCE
const NORMAL_SPEED = 50
const RUN_SPEED = 80
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 400
@export var attack_range = 80

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size #Vector de resolución de pantalla
	position = Vector2(randi_range(0, screen_size.x), randi_range(0, screen_size.y))
	$Sword1/Hitbox_Sword1.disabled = true # La hitbox (espada) empieza emvainadas
	$Sword2/Hitbox_Sword2.disabled = true
	# Configura y agrega el temporizador al nodo actual
	attack_timer = Timer.new()
	# El tiempo de espera del input del 2º ataque es la duracion del primer ataque
	attack_timer.wait_time = $AnimationPlayer.get_animation("attack_down").length
	attack_timer.one_shot = true  # Solo se ejecuta una vez
	add_child(attack_timer)
	attack_timer.connect("timeout", self._on_attack_timer_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# "Timer" para el movimiento random
	timer -= delta
	if timer <= 0:
		print(move_chance)
		change_direction()
	set_directionVector_string()
	if !is_attacking && !is_blocking && !is_hurt && !was_parried:
		move(delta) # Nos movemos si se ha pulsado algo
	#if Input.is_action_just_pressed("attack"):	
	attack()
	depth_control()

func move(delta):
	var player_position = get_player_position()
	if (player_position != null):
		if (position.distance_to(player_position) <= detection_range):
			move_towards_player(player_position, delta)
		else:
			move_randomly(delta)
	else:
		move_randomly(delta)
	if is_attacking == false && is_blocking == false && is_hurt == false && direction_vector != Vector2(0,0):
		$AnimationPlayer.play(str("run_" + direction_str))
	elif is_attacking == false && is_blocking == false && is_hurt == false: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
		$AnimationPlayer.play(str("iddle_" + direction_str))

func move_randomly(delta):
	speed = NORMAL_SPEED
	position += direction_vector * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
func move_towards_player(player_position: Vector2, delta: float):
	speed = RUN_SPEED
	direction_vector = (player_position - position).normalized()
	position += direction_vector * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)

# Función de ataque. Si ha sido pulsado y no estamos bloqueando ni reciviendo daño, tiene lugar	
func attack():
	var player_position = get_player_position()
	if (player_position != null):
		if (position.distance_to(player_position) <= attack_range):
			if !is_blocking && !is_hurt && !was_parried:
				if is_attacking == false:
					slash_VFX.play()
					$AnimationPlayer.play(str("attack_" + direction_str))
					attack_timer.start()  # Inicia el temporizador
				elif attack_timer.time_left > 0 && !second_attack_queued:
					# Si la animación de ataque 1 está en curso y el temporizador no ha terminado
					second_attack_queued = true

func get_parried():
	$AnimationPlayer.play(str("parried_") + direction_str)
	status()

# Callback cuando la animación de ataque termina
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack_"):
		if second_attack_queued:
			$AnimationPlayer.play(str("attack_" + direction_str))
			$AnimationPlayer.stop(false)
			slash_VFX.play()
			$AnimationPlayer.play(str("attack_" + direction_str + "_2"))  # Reproducir la segunda animación de ataque
			second_attack_queued = false

func _on_attack_timer_timeout():
	# Cuando el temporizador se agota, resetea la cola de ataque
	second_attack_queued = false

#Función de bloqueo. Funciona de manera practicamente idéntica a ataque, aunque la hitbox y su uso no está implementado
func block():
	if is_attacking == false && is_blocking == false && is_hurt == false:
		block_VFX.play()
		$AnimationPlayer.play(str("block_" + direction_str))

# Función de recivir daño. Solo se activa cuando la hurtbox del personaje detecte una hitbox 
# con un valor de daño asociado que llamaremos amount		
func take_damage(damage: int, knockback_direction: Vector2, knockback_strength: int) -> void:
	life -= damage
	if life <= 0:
		kill()
	elif not is_hurt:
		hurt_VFX.play()
		is_hurt = true
		is_attacking = false
		is_blocking = false
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration
		speed = 0
		$AnimationPlayer.play(str("damage_" + direction_str))
		#$KnightSprite.connect("animation_finished", self._on_hurt_animation_finished)
		await get_tree().create_timer(0.6).timeout
		is_hurt = false
		
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		position += knockback_velocity * delta  # Actualiza la posición manualmente
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		# Reduce el temporizador del retroceso
		knockback_timer -= delta

# Animación que se reproduce al morir
func kill():
	hurt_VFX.pitch_scale = 0.6
	hurt_VFX.play()
	is_hurt = true # Ponemos el estado de ser dañado simplemente para bloquear otras acciones
	speed = 0; # Ya no nos movemos mas, por si acaso, aunque creo que no hace falta
	$AnimationPlayer.play(str("death_" + direction_str))  #Animación de el cuerpo me pide tierra
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	
func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	# Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	z_index = normalized_Y_pos * 2*RenderingServer.CANVAS_ITEM_Z_MAX + RenderingServer.CANVAS_ITEM_Z_MIN
	
func get_player_position():
	if get_parent() != null:
		var parent = get_parent()
		if parent.has_node("Player"):
			return parent.get_node("Player").position
	return null
	
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

func status():
	print("...............")
	print("is_attacking: ")
	print(is_attacking)
	print("is_blocking: ")
	print(is_blocking)
	print("is_hurt: ")
	print(is_hurt)
