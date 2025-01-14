extends CharacterBody2D
class_name Frog

@export var MAX_HEALTH = 3
@export var health = MAX_HEALTH
var MOVE_CHANCE = 0.8
@export var is_hurt = false
@onready var screen_size = get_viewport_rect().size
const NORMAL_SPEED = 0
const JUMP_SPEED = 65
@export var is_jumping = false
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 80
var JUMP_INTERVAL: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial
var direction_str = "down"
@onready var healthbar = $Healthbar
@onready var damagebar = $Healthbar/Damagebar
@onready var timer_vida = $Healthbar/Timer
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	global_position = Globals.find_valid_spawn_position(global_position, self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_hurt == false: # Mientras no esté siendo herido, el limo se mueve normal
		move(delta)
	z_index = Globals.depth_control(position, screen_size)
	# Actualiza el timer para cambiar la dirección
	timer -= delta

# Literalmente lo mismo que la del caballero pero mas facil. Id a mirar los comentarios en knight.gd
func take_damage(ammount: int, knockback_direction: Vector2, knockback_strength) -> void:
	timer = JUMP_INTERVAL/2
	health -= ammount
	timer_vida.start()
	healthbar.update()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	if health <= 0:
		kill()
	elif is_hurt == false:  # Verifica que el enemigo no esté ya en animación de daño
		is_hurt = true
		$SFX/Hurt.play()
		$AnimationPlayer.play(str("damage_" + direction_str))
		
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

# Función de me voy con San Pedro del limo
func kill():
	$SFX/Hurt.pitch_scale = 0.7
	$SFX/Hurt.play()
	is_hurt = true
	speed = 0
	$AnimationPlayer.play(str("death_" + direction_str))
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	await get_tree().create_timer(0.9).timeout
	queue_free()
	
func move(delta):
	velocity = Vector2.ZERO
	var player_position = Globals.get_player_position(self)
	if timer <= 0:
		timer = JUMP_INTERVAL
		direction = Globals.get_random_direction(position, MOVE_CHANCE)
		if (player_position != null):
			if (position.distance_to(player_position) <= detection_range):
				direction = (player_position - position).normalized()
				timer = JUMP_INTERVAL
		direction_str = Globals.set_directionVector_string(direction)
		is_jumping = direction != Vector2.ZERO
	if is_jumping:
		collision_mask = 19 #Mirad la documentacion de las mascaras de colision si no entendeis esto
		collision_layer = 64
		speed = JUMP_SPEED
		$SFX/Leap.play()
		$AnimationPlayer.play(str("jump_" + direction_str))
	else:
		collision_mask = 51 #Mirad la documentacion de las mascaras de colision si no entendeis esto
		collision_layer = 2
		speed = NORMAL_SPEED
		direction = Vector2.ZERO
		$AnimationPlayer.play(str("iddle_" + direction_str))
	position += direction * speed * delta
	move_and_slide()
		
	
