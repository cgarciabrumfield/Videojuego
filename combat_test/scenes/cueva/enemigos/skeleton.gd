extends CharacterBody2D

@export var MAX_HEALTH = 3
@export var health = MAX_HEALTH
var screen_size # Size of the game window.
var direction_str = "down" # Izquierda derecha arriba abajo, segun a donde mire
var direction_vector
var is_attacking = false # Si está atacando bloquea las demás acciones y entradas
var is_blocking = false # Si está bloqueando bloquea las demás acciones y entradas
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@export var is_hurt = false # Al recibir daño se bloquean las demas acciones y entradas
var was_parried = false
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
@onready var slash_VFX = $VFXs/Sword_VFX
@onready var hurt_VFX = $VFXs/hurt_VFX
@onready var walk_VFX = $VFXs/walk_stone_VFX
@onready var block_VFX = $VFXs/block_VFX

@onready var healthbar = $Healthbar
@onready var damagebar = $Healthbar/Damagebar
@onready var timer_vida = $Healthbar/Timer
var attack_count = 0
var attack_cooldown_time = 1.0  # 1 segundo entre ataques
@onready var attack_cooldown_timer = Timer.new()
# Movement
const MOVE_CHANCE = 0.7
const NORMAL_SPEED = 30
const RUN_SPEED = 25
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 50
@export var attack_range = 18

var dead = false
@export var revive_time = 10
@onready var revive_timer = $ReviveTimer

var near_player = false
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	SkeletonsState.add_skeleton()
	global_position = Globals.find_valid_spawn_position(global_position, self)
	screen_size = get_viewport_rect().size #Vector de resolución de pantalla
	$Sword1/Hitbox_Sword1.disabled = true # La hitbox (espada) empieza emvainadas
	add_child(attack_cooldown_timer)
	attack_cooldown_timer.wait_time = attack_cooldown_time
	attack_cooldown_timer.one_shot = true
	revive_timer.wait_time = revive_time

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# "Timer" para el movimiento random
	if !is_attacking && !is_blocking && !is_hurt && !was_parried:
		timer -= delta
		if timer <= 0 and !near_player:
			direction_vector = Globals.get_random_direction(position, MOVE_CHANCE)
			timer = direction_change_interval
		direction_str = Globals.set_directionVector_string(direction_vector)
		move(delta) # Nos movemos si se ha pulsado algo
		attack()
		z_index = Globals.depth_control(position, screen_size)
	if dead and SkeletonsState.check_skeletons() == 0:
		var tween = create_tween()
		tween.tween_property($KnightSprite, "modulate:a", 0, 1)
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		await get_tree().create_timer(0.9).timeout
		queue_free()

func move(delta):
	velocity = Vector2.ZERO
	var player_position = Globals.get_player_position(self)
	if (player_position != null):
		if (position.distance_to(player_position) <= detection_range):
			near_player = true
			if !(position.distance_to(player_position) <= attack_range):
				move_towards_player(player_position, delta)
		else:
			move_randomly(delta)
			near_player = false
	else:
		move_randomly(delta)
		near_player = false
	
	if is_attacking == false && is_blocking == false && is_hurt == false && direction_vector != Vector2(0,0):
		$AnimationPlayer.play(str("run_" + direction_str))
	elif is_attacking == false && is_blocking == false && is_hurt == false: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
		$AnimationPlayer.play(str("iddle_" + direction_str))
	move_and_slide()

func move_randomly(delta):
	speed = NORMAL_SPEED
	position += direction_vector * speed * delta
	
func move_towards_player(player_position: Vector2, delta: float):
	speed = RUN_SPEED
	direction_vector = (player_position - position).normalized()
	position += direction_vector * speed * delta

# Función de ataque. Si ha sido pulsado y no estamos bloqueando ni reciviendo daño, tiene lugar	
func attack():
	var player_position = Globals.get_player_position(self)
	if player_position != null:
		if position.distance_to(player_position) <= attack_range:
			if !is_blocking and !is_hurt and !was_parried:
				if !is_attacking and attack_cooldown_timer.is_stopped():
					# Verifica si no está atacando y si ya pasó el cooldown de 1 segundo
					is_attacking = true
					slash_VFX.play()
					$Exclamation.modulate = Color.WHITE
					$AnimationPlayer.play("attack_" + direction_str)
					# Reinicia el temporizador de cooldown entre ataques
					attack_cooldown_timer.start()

func get_parried():
	$AnimationPlayer.play(str("parried_") + direction_str)
	status()

# Función de recivir daño. Solo se activa cuando la hurtbox del personaje detecte una hitbox 
# con un valor de daño asociado que llamaremos amount		
func take_damage(damage: int, knockback_direction: Vector2, knockback_strength: int) -> void:
	health -= damage
	timer_vida.start()
	$Healthbar.update()
	if health <= 0:
		faint()
	elif not is_hurt:
		hurt_VFX.play()
		is_hurt = true
		is_attacking = false
		knockback_velocity = knockback_direction * knockback_strength
		knockback_timer = knockback_duration
		speed = 0
		$AnimationPlayer.play(str("damage_" + direction_str))
		#$KnightSprite.connect("animation_finished", self._on_hurt_animation_finished)
		await get_tree().create_timer(0.6).timeout
		is_hurt = false
		
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
	await get_tree().create_timer(0.9).timeout
	queue_free()
	
func faint():
	revive_timer.start()
	hurt_VFX.pitch_scale = 0.6
	hurt_VFX.play()
	is_hurt = true # Ponemos el estado de ser dañado simplemente para bloquear otras acciones
	speed = 0; # Ya no nos movemos mas, por si acaso, aunque creo que no hace falta
	collision_layer = 0
	SkeletonsState.faint_skeleton()
	damagebar.visible = false
	healthbar.visible = false
	$Shadow.visible = false
	$AnimationPlayer.play(str("faint_" + direction_str))  #Animación de el cuerpo me pide tierra
	if SkeletonsState.check_skeletons() == 0:
		kill()
	else:
		dead = true

func revive():
	hurt_VFX.pitch_scale = 0.4
	hurt_VFX.play()
	$AnimationPlayer.play(str("revive_" + direction_str))
	dead = false
	damagebar.visible = true
	healthbar.visible = true
	$Shadow.visible = true
	health = 1
	damagebar.update()
	healthbar.update()
	await get_tree().create_timer(0.9).timeout
	hurt_VFX.pitch_scale = 1
	collision_layer = 2
	speed = RUN_SPEED
	SkeletonsState.add_skeleton()

func _on_revive_timer_timeout() -> void:
	revive()
	revive_timer.stop()

func status():
	print("...............")
	print("is_attacking: ")
	print(is_attacking)
	print("is_blocking: ")
	print(is_blocking)
	print("is_hurt: ")
	print(is_hurt)
