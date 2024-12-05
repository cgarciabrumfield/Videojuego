extends CharacterBody2D
class_name Mushroom_man

@export var MAX_HEALTH = 5
@export var health = MAX_HEALTH
@export var is_hurt = false
const NORMAL_SPEED = 15
const RUN_SPEED = 40
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 100
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
@onready var screen_size = get_viewport_rect().size
@onready var healthbar = $Healthbar
@onready var damagebar = $Healthbar/Damagebar
@onready var timer_vida = $Healthbar/Timer
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0
var player_position
# Movimiento
var direction_str = "down" # Izquierda derecha arriba abajo, segun a donde mire
var direction_vector
var rotation_vector
const MOVE_CHANCE = 0.4
#Ataques
@export var is_attacking = false
@export var attack_range = 60
var attack_cooldown_time = 3.0  # segundos entre ataques
@export var can_attack = false
@onready var attack_timer = $AttackTimer
@onready var proyectil_scene = preload("res://scenes/projectile.tscn")
#Sonidos

func _ready():
	MushroomState.relax()
	attack_timer.wait_time = attack_cooldown_time
	attack_timer.start()

func _process(delta):
	print(position)
	MushroomState.update_timer(delta)
	# "Timer" para el movimiento random
	if !is_attacking:
		timer -= delta
		if timer <= 0:
			direction_vector = Globals.get_random_direction(position, MOVE_CHANCE, MushroomState.is_nervous)
			timer = direction_change_interval
		direction_str = Globals.set_directionVector_string(direction_vector)
		if !is_hurt:
			move(delta) # Nos movemos si se ha pulsado algo
		z_index = Globals.depth_control(position, screen_size)
	player_position = Globals.get_player_position(self)
	
func take_damage(ammount: int, knockback_direction: Vector2, knockback_strength) -> void:
	health -= ammount
	timer_vida.start()
	healthbar.update()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	if health <= 0:
		kill()
	elif is_hurt == false:  # Verifica que el enemigo no esté ya en animación de daño
		is_hurt = true
		MushroomState.make_nervous()
		is_attacking = false
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

func kill():
	is_hurt = true
	can_attack = false
	is_attacking = false
	attack_timer.stop()
	$AnimationPlayer.play(str("death_" + direction_str))
	await get_tree().create_timer(0.9).timeout
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	queue_free()
	
func move(delta):
	velocity = Vector2.ZERO
	if (player_position != null):
		if (MushroomState.is_nervous):
			if MushroomState.is_fleeing:
				direction_vector = (position - player_position).normalized()
			speed = RUN_SPEED
		else:
			speed = NORMAL_SPEED
	else:
		speed = NORMAL_SPEED
	position += direction_vector * speed * delta

	if !is_attacking && !is_hurt && direction_vector != Vector2(0,0):
		$AnimationPlayer.play(str("run_" + direction_str))
		$AnimationPlayer.speed_scale = 0.5
	elif !is_attacking && !is_hurt: #Si no estamos corriendo y tampoco hemos sido heridos, animación iddle
		$AnimationPlayer.play(str("iddle_" + direction_str))
		$AnimationPlayer.speed_scale = 0.5
	move_and_slide()

func status():
	print("...............")
	print("can_attack: ")
	print(can_attack)
	print("is_hurt: ")
	print(is_hurt)
