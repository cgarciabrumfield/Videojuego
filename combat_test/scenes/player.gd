class_name Player
extends CharacterBody2D

#Modifiable stats
@export var WALK_SPEED = GameState.WALK_SPEED # How fast the player will move (pixels/sec). default:45
@export var RUN_SPEED = GameState.RUN_SPEED
@export var MAX_HEALTH = GameState.MAX_HEALTH
@export var MAX_STAMINA = GameState.MAX_STAMINA
var STAMINA_REGEN = GameState.STAMINA_REGEN #porcentaje de la barra de estamina que regenera por segundo
@export var RUN_STAMINA_COST_SEC = GameState.RUN_STAMINA_COST_SEC
@export var ATTACK_STAMINA_COST = GameState.ATTACK_STAMINA_COST
@export var STAMINA_REGEN_TIMER_TIMEOUT = GameState.STAMINA_REGEN_TIMER_TIMEOUT

#speed
var speed = WALK_SPEED
#Health
var health = MAX_HEALTH
#Stamina
var stamina = MAX_STAMINA
var stamina_regen = STAMINA_REGEN
var stamina_run_cost_sec = RUN_STAMINA_COST_SEC
var attack_stamina_cost = ATTACK_STAMINA_COST

@export var can_regen_stamina = true
@onready var timer_stamina = $CanvasLayer/Staminabar/Timer
@onready var healthbar = $CanvasLayer/Healthbar
@onready var timer_vida = $CanvasLayer/Healthbar/Timer
@onready var damagebar = $CanvasLayer/Healthbar/Damagebar
@onready var staminabar = $CanvasLayer/Staminabar
var screen_size # Size of the game window.
var direction # Izquierda derecha arriba abajo, segun a donde mire
@export var is_attacking = false # Si está atacando bloquea las demás acciones y entradas
@export var is_blocking = false # Si está bloqueando bloquea las demás acciones y entradas
@export var is_parrying = false
@export var is_inmune = false
@export var is_hurt = false # Al recibir daño se bloquean las demas acciones y entradas
@export var is_running = false
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@export var inmune_time = 1.5
var inmune_timer = Timer.new()
# Parry timer
var parry_timer = Timer.new()
# Variable para el temporizador de enfriamiento
var attack_timer = Timer.new()
var second_attack_queued = false
@onready var slash_SFX = $SFXs/Sword_SFX
@onready var hurt_SFX = $SFXs/hurt_SFX
@onready var walk_SFX = $SFXs/walk_grass_SFX
@onready var block_SFX = $SFXs/block_SFX
@onready var parry_SFX = $SFXs/parry_SFX
@onready var guard_broken_SFX = $SFXs/break_guard_SFX

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0

func save():
	var save_dict = {
		"WALK_SPEED" : WALK_SPEED,
		"RUN_SPEED" : RUN_SPEED,
		"MAX_HEALTH": MAX_HEALTH,
		"health": health,
		"MAX_STAMINA" : MAX_STAMINA,
		"stamina" : MAX_STAMINA,
		"stamina_regen" : stamina_regen,
		"RUN_STAMINA_COST_SEC": RUN_STAMINA_COST_SEC,
		"attack_stamina_cost" : attack_stamina_cost,
		"STAMINA_REGEN_TIMER_TIMEOUT": STAMINA_REGEN_TIMER_TIMEOUT
	}
	return save_dict

# Called when the node enters the scene tree for the first time.
func _ready():
	if "level" in get_parent().get_parent():
		$darkness.visible = get_parent().get_parent().level == "cueva"
	else:
		$darkness.visible = false
	screen_size = get_viewport_rect().size #Vector de resolución de pantalla
	direction = str("down") # El personaje empieza mirando hacia abajo
	 #position = screen_size / 2 # situamos al personaje en el centro de la pantalla
	$Sword1/Hitbox_Sword1.disabled = true # La hitbox (espada) empieza envainadas
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
	timer_stamina.wait_time = STAMINA_REGEN_TIMER_TIMEOUT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move(delta) # Nos movemos si se ha pulsado algo
	if Input.is_action_just_pressed("attack"):	
		attack()
	if Input.is_action_just_pressed("block"):	
		block() # Bloqueamos si procede
	depth_control()
	stamina_control(delta)

func move(delta): # Función que mueve al personaje
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
			if Input.is_action_pressed("run") and stamina > 0:
				if !is_running:
					var tween1 = create_tween()
					var tween2 = create_tween()
					tween1.tween_property(self, "speed", RUN_SPEED, 0.5)
					tween2.tween_property($AnimationPlayer, "speed_scale", 1.5, 0.5)
					is_running = true
				stamina -= RUN_STAMINA_COST_SEC * delta
				timer_stamina.start()
				$AnimationPlayer.speed_scale = 1.5
			elif stamina <= 0 and !Input.is_action_just_released("run") and is_running:
					var tween1 = create_tween()
					var tween2 = create_tween()
					tween1.tween_property(self, "speed", WALK_SPEED*0.5, 0.5)
					tween2.tween_property($AnimationPlayer, "speed_scale", 0.5, 0.5)
			else:
				Input.action_release("run")
				if is_running:
					is_running = false
					var tween1 = create_tween()
					var tween2 = create_tween()
					tween1.tween_property(self, "speed", WALK_SPEED, 0.5)
					tween2.tween_property($AnimationPlayer, "speed_scale", 1, 0.5)
			$AnimationPlayer.play(str("run_" + direction))
		elif !is_attacking && !is_blocking && !is_hurt && !is_parrying: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
			$AnimationPlayer.play(str("iddle_" + direction))
		# Actualizamos la posición según el vector de dirección y delta (constancia fps)
		#position += velocity * delta
		move_and_slide()
		#position = position.clamp(Vector2.ZERO, screen_size)
# Función de ataque. Si ha sido pulsado y no estamos bloqueando ni reciviendo daño, tiene lugar	
func attack():
	if stamina <= 0 or is_blocking or is_hurt or is_parrying:
		return
	if !is_attacking:
		slash_SFX.play()
		$AnimationPlayer.play(str("attack_" + direction))
		stamina -= attack_stamina_cost
		attack_timer.start()  # Inicia el temporizador
	elif attack_timer.time_left > 0 && !second_attack_queued:
		# Si la animación de ataque 1 está en curso y el temporizador no ha terminado
		second_attack_queued = true

# Callback cuando la animación de ataque termina
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name.begins_with("attack_") and stamina > 0:
		if second_attack_queued:
			$AnimationPlayer.play(str("attack_" + direction))
			$AnimationPlayer.stop(false)
			slash_SFX.play()
			stamina -= attack_stamina_cost
			$AnimationPlayer.play(str("attack_" + direction + "_2"))  # Reproducir la segunda animación de ataque
			second_attack_queued = false

func _on_attack_timer_timeout():
	# Cuando el temporizador se agota, resetea la cola de ataque
	second_attack_queued = false


#Función de bloqueo. Funciona de manera practicamente idéntica a ataque, aunque la hitbox y su uso no está implementado
func block():
	if !is_attacking && !is_blocking && !is_hurt && !is_parrying:
		$SFXs/Raise_guard_SFX.play()
		parry_timer.start()
		$AnimationPlayer.play(str("shield_up_frame_" + direction))
		
func _input(event):
	if event.is_action_released("block"):
		if parry_timer.time_left > 0:
			print("Parry")
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
			stamina -= damage * 10
			if stamina > 0:
				block_SFX.play() 
			else:
				guard_broken_SFX.play()
			can_regen_stamina = false
			timer_stamina.start()
			return
	health -= damage
	healthbar.update()
	timer_vida.start()
	is_blocking = false
	is_parrying = false
	is_inmune = true
	is_attacking = false
	hurt_SFX.play()
	if health <= 0:
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
		parry_SFX.play()
		$Animation_parry_effect.play(str("parry_" + direction))
		attacker.get_parried()

# Animación que se reproduce al morir
func kill():
	hurt_SFX.pitch_scale = 0.8
	hurt_SFX.play()
	is_hurt = true # Ponemos el estado de ser dañado simplemente para bloquear otras acciones
	speed = 0; # Ya no nos movemos mas, por si acaso, aunque creo que no hace falta
	$AnimationPlayer.play(str("death_" + direction))  #Animación de el cuerpo me pide tierra
	await get_tree().create_timer(0.8).timeout  # Esperamos a que termine y eliminamos el pj
	get_tree().reload_current_scene() #TODO realmente aquí iria la pantalla de gameover o la cinematica de revivir, etc
	
func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	# Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	z_index = normalized_Y_pos * 90 + 11
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

func _on_health_timer_timeout() -> void:
	damagebar.update()
	timer_vida.stop()

func stamina_control(delta):
	if stamina <= 0:
		if is_blocking:
			$AnimationPlayer.play(str("stop_block_") + direction)
		second_attack_queued = false
	if stamina < 0 and can_regen_stamina:
		stamina = 0
	if stamina > MAX_STAMINA:
		stamina = MAX_STAMINA
	if is_blocking:
		stamina_regen = STAMINA_REGEN * 0.3
	else:
		stamina_regen = STAMINA_REGEN
	if is_attacking or is_running:
		can_regen_stamina = false
		timer_stamina.start()
	if stamina < MAX_STAMINA and can_regen_stamina:
		stamina += stamina_regen * MAX_STAMINA * delta
	staminabar.update()

func _on_stamina_timer_timeout() -> void:
	can_regen_stamina = true
	timer_stamina.stop()

func update_stats():
	#speed
	speed = WALK_SPEED
	#Health
	health = MAX_HEALTH
	#Stamina
	stamina = MAX_STAMINA
	stamina_regen = STAMINA_REGEN
	stamina_run_cost_sec = RUN_STAMINA_COST_SEC
	attack_stamina_cost = ATTACK_STAMINA_COST
	
