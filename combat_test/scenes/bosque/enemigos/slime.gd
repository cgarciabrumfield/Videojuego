extends CharacterBody2D

@export var MAX_HEALTH = 3
@export var health = MAX_HEALTH
var MOVE_CHANCE = 0.7
var is_hurt = false
var screen_size
const NORMAL_SPEED = 15
const RUN_SPEED = 25
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 50
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@onready var hurt_VFX = $hurt_vfx
@onready var healthbar = $Healthbar
@onready var damagebar = $Healthbar/Damagebar
@onready var timer_vida = $Healthbar/Timer
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	var colors = [Color.YELLOW_GREEN, Color.MEDIUM_SPRING_GREEN, Color.SPRING_GREEN, Color.DARK_GREEN]
	$SlimeSprite.modulate = colors[randi() % colors.size()]
	$SlimeSprite.modulate.a8 = 160

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_hurt == false: # Mientras no esté siendo herido, el limo se mueve normal
		move(delta)
		$SlimeSprite.play("default")
	z_index = Globals.depth_control(position, screen_size)
	# Actualiza el timer para cambiar la dirección
	timer -= delta
	if timer <= 0:
		direction = Globals.get_random_direction(position, MOVE_CHANCE)


# Literalmente lo mismo que la del caballero pero mas facil. Id a mirar los comentarios en knight.gd
func take_damage(ammount: int, knockback_direction: Vector2, knockback_strength) -> void:
	hurt_VFX.play()
	health -= ammount
	timer_vida.start()
	healthbar.update()
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	if health <= 0:
		kill()
	elif is_hurt == false:  # Verifica que el enemigo no esté ya en animación de daño
		$AnimationPlayer.play("damage")
		
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
	$AnimationPlayer.play("death")
	await get_tree().create_timer(0.9).timeout
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	queue_free()
	
func move(delta):
	velocity = Vector2.ZERO
	var player_position = Globals.get_player_position(self)
	if (player_position != null):
		if (position.distance_to(player_position) <= detection_range):
			move_towards_player(player_position, delta)
			return
	move_randomly(delta)

func move_randomly(delta):
	speed = NORMAL_SPEED
	$SlimeSprite.speed_scale = 1
	position += direction * speed * delta
	move_and_slide()
	
func move_towards_player(player_position: Vector2, delta: float):
	speed = RUN_SPEED
	$SlimeSprite.speed_scale = 2
	direction = (player_position - position).normalized()
	position += direction * speed * delta
	move_and_slide()
