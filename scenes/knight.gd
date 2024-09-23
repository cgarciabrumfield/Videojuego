extends CharacterBody2D

@export var speed = 200 # How fast the player will move (pixels/sec).
@export var life = 100
var screen_size # Size of the game window.
var direction # Izquierda derecha arriba abajo, segun a donde mire
@export var is_attacking = false # Si está atacando bloquea las demás acciones y entradas
@export var is_blocking = false # Si está bloqueando bloquea las demás acciones y entradas
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@export var is_hurt = false # Al recibir daño se bloquean las demas acciones y entradas
var is_inmune = false
@export var inmune_time = 1.5
var inmune_timer = Timer.new()
# Variable para el temporizador de enfriamiento
var attack_timer = Timer.new()
var second_attack_queued = false
@onready var slash_VFX = $VFXs/Sword_VFX
@onready var hurt_VFX = $VFXs/hurt_VFX
@onready var walk_VFX = $VFXs/walk_grass_VFX
@onready var block_VFX = $VFXs/block_VFX

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var screen = get_limits_of_movement() #get_limits_of_movement() #Vector de resolución de pantalla
	screen_size = screen.texture.get_size()
	direction = str("down") # El personaje empieza mirando hacia abajo
	position = screen.position # situamos al personaje en el centro de la pantalla
	$Sword1/Hitbox_Sword1.disabled = true # La hitbox (espada) empieza emvainadas
	$Sword2/Hitbox_Sword2.disabled = true
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
	

func _on_inmune_timer_timeout():
	is_inmune = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move(delta) # Nos movemos si se ha pulsado algo
	if Input.is_action_just_pressed("attack"):	
		attack()
	if Input.is_action_just_pressed("block"):	
		block() # Bloqueamos si procede
	#status()

func move(delta): # Función que mueve al personaje
	var velocity = Vector2.ZERO #Vector de movimiento del jugador
	if is_attacking == false && is_blocking == false && is_hurt == false:
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
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
			$AnimationPlayer.play(str("run_" + direction))
		else: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
			$AnimationPlayer.play(str("iddle_" + direction))
		
		# Actualizamos la posición según el vector de dirección y delta (constancia fps)
		position += velocity * delta
		velocity = move_and_slide()
		position = position.clamp(-screen_size/2, screen_size/2)
		
func get_limits_of_movement():
	if get_parent() != null:
		var parent = get_parent()
		if parent.has_node("sala"):
			#sprite.texture.get_size()
			return parent.get_node("sala/Suelo")
	return null
	
# Función de ataque. Si ha sido pulsado y no estamos bloqueando ni reciviendo daño, tiene lugar	
func attack():
	if is_blocking == false && is_hurt == false:
		if is_attacking == false:
			slash_VFX.play()
			$AnimationPlayer.play(str("attack_" + direction)) #las diagonales parecen dar error
			attack_timer.start()  # Inicia el temporizador
		elif attack_timer.time_left > 0 && second_attack_queued == false:
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
	if is_attacking == false && is_blocking == false && is_hurt == false:
		block_VFX.play()
		$AnimationPlayer.play(str("block_" + direction))

# Función de recivir daño. Solo se activa cuando la hurtbox del personaje detecte una hitbox 
# con un valor de daño asociado que llamaremos amount		
func take_damage(damage: int, knockback_direction: Vector2,
 knockback_strength: int, attacker: Node2D, can_be_parried: bool) -> void:
	if is_inmune:
		return
	if is_blocking and can_be_parried:
		try_parry(attacker)
		return
	is_blocking = false
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
		
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		position += knockback_velocity * delta  # Actualiza la posición manualmente
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		# Reduce el temporizador del retroceso
		knockback_timer -= delta

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
		$Animation_parry_effect.play(str("parry_" + direction))
		attacker.get_parried()
		status()
		is_blocking = false
		status()

# Animación que se reproduce al morir
func kill():
	hurt_VFX.pitch_scale = 0.8
	hurt_VFX.play()
	is_hurt = true # Ponemos el estado de ser dañado simplemente para bloquear otras acciones
	speed = 0; # Ya no nos movemos mas, por si acaso, aunque creo que no hace falta
	$AnimationPlayer.play(str("death_" + direction))  #Animación de el cuerpo me pide tierra
	await get_tree().create_timer(0.8).timeout  # Esperamos a que termine y eliminamos el pj
	get_tree().reload_current_scene() #TODO realmente aquí iria la pantalla de gameover o la cinematica de revivir, etc
	
func status():
	print("...............")
	print("is_attacking: ")
	print(is_attacking)
	print("is_blocking: ")
	print(is_blocking)
	print("is_hurt: ")
	print(is_hurt)
