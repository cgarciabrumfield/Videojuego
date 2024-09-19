extends Area2D

@export var speed = 200 # How fast the player will move (pixels/sec).
@export var life = 3
var screen_size # Size of the game window.
var direction #izquierda derecha arriba abajo, segun a donde mire
@export var is_attacking = false #Si está atacando bloquea las demás acciones y entradas
@export var is_blocking = false #Si está bloqueando bloquea las demás acciones y entradas
var normalized_Y_pos #Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@export var is_hurt = false #Al recibir daño se bloquean las demas acciones y entradas
# Variable para el temporizador de enfriamiento
var attack_timer = Timer
var second_attack_queued = false
@onready var slash_VFX = $VFXs/Sword_VFX
@onready var hurt_VFX = $VFXs/hurt_VFX
@onready var walk_VFX = $VFXs/walk_grass_VFX

@export var knockback_strength: float = 300  # Fuerza del retroceso
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size #Vector de resolución de pantalla
	direction = str("down") #El personaje empieza mirando hacia abajo
	position = screen_size / 2 #situamos al personaje en el centro de la pantalla
	$Sword1/Hitbox_Sword1.disabled = true #La hitbox (espada) empieza emvainadas
	$Sword2/Hitbox_Sword2.disabled = true
	# Configura y agrega el temporizador al nodo actual
	attack_timer = Timer.new()
	#El tiempo de espera del input del 2º ataque es la duracion del primer ataque
	attack_timer.wait_time = $AnimationPlayer.get_animation("attack_down").length
	attack_timer.one_shot = true  # Solo se ejecuta una vez
	add_child(attack_timer)

	attack_timer.connect("timeout", self._on_attack_timer_timeout)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	move(delta) #Nos movemos si se ha pulsado algo
	if Input.is_action_just_pressed("attack"):	
		attack()
	block() #Bloqueamos si procede
	depth_control()

func move(delta): #Función que mueve al personaje
	var velocity = Vector2.ZERO #Vector de movimiento del jugador
	if is_attacking == false && is_blocking == false && is_hurt == false:
		if Input.is_action_pressed("right"):
			velocity.x += 1
			#Actualizamos la dirección en la que mira el personaje, para todas las animaciones
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
		#Si nos estamos moviendo, y no hemos sido heridos, animación de correr. 
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
			$AnimationPlayer.play(str("run_" + direction))
		else: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
			$AnimationPlayer.play(str("iddle_" + direction))
		#Actualizamos la posición según el vector de dirección y delta (constancia fps)
		position += velocity * delta
		position = position.clamp(Vector2.ZERO, screen_size)
#Función de ataque. Si ha sido pulsado y no estamos bloqueando ni reciviendo daño, tiene lugar	
func attack():
	if is_blocking == false && is_hurt == false:
		if is_attacking == false:
			slash_VFX.play()
			$AnimationPlayer.play(str("attack_" + direction))
			attack_timer.start()  # Inicia el temporizador
		elif attack_timer.time_left > 0 && second_attack_queued == false:
			# Si la animación de ataque 1 está en curso y el temporizador no ha terminado
			second_attack_queued = true

# Callback cuando la animación de ataque termina
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack_"):
		if second_attack_queued:
			print("a")
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
	if Input.is_action_just_pressed("block") && is_attacking == false && is_blocking == false:
		is_blocking = true
		$KnightSprite.play(str("block_" + direction))
		await get_tree().create_timer(0.8).timeout
		is_blocking = false

#Función de recivir daño. Solo se activa cuando la hurtbox del personaje detecte una hitbox 
# con un valor de daño asociado que llamaremos amount		
func take_damage(damage: int, knockback_direction: Vector2) -> void:
	hurt_VFX.play()
	life -= damage
	if life <= 0:
		kill()
	elif not is_hurt:
		is_hurt = true
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration
		$KnightSprite.play(str("damage_" + direction))
		$KnightSprite.connect("animation_finished", self._on_hurt_animation_finished)
		
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		position += knockback_velocity * delta  # Actualiza la posición manualmente
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		#Reduce el temporizador del retroceso
		knockback_timer -= delta
		
func _on_hurt_animation_finished():
	if $KnightSprite.animation == str("damage_" + direction):  # Verifica si la animación terminada es "hurt"
		$KnightSprite.disconnect("animation_finished", self._on_hurt_animation_finished)
		is_hurt = false #Quitamos el estado de estar siendo dañados, ya podemos volver a controlar al pj
		print("test1")
		await get_tree().create_timer(0.8).timeout
		print("test2")
#Animación que se reproduce al morir
func kill():
	is_hurt = true #Ponemos el estado de ser dañado simplemente para bloquear otras acciones
	speed = 0; #Ya no nos movemos mas, por si acaso, aunque creo que no hace falta
	$KnightSprite.play(str("death_" + direction)) #Animación de el cuerpo me pide tierra
	await get_tree().create_timer(0.8).timeout  #Esperamos a que termine y eliminamos el pj
	get_tree().reload_current_scene() #TODO realmente aquí iria la pantalla de gameover o la cinematica de revivir, etc

func depth_control():
	#Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	#Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	z_index = normalized_Y_pos * 2*RenderingServer.CANVAS_ITEM_Z_MAX + RenderingServer.CANVAS_ITEM_Z_MIN
