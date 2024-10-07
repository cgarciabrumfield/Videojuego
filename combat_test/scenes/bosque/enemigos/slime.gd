extends CharacterBody2D

@export var maxHealth = 3
@export var health = maxHealth
var is_hurt = false
var screen_size
const NORMAL_SPEED = 50
const RUN_SPEED = 80
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 200
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
	health = maxHealth
	screen_size = get_viewport_rect().size
	position = Vector2(randi_range(0, screen_size.x), randi_range(0, screen_size.y))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_hurt == false: # Mientras no esté siendo herido, el limo se mueve normal
		move(delta)
		$SlimeSprite.play("default")
	depth_control()
	# Actualiza el timer para cambiar la dirección
	timer -= delta
	if timer <= 0:
		change_direction()
		
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
	var player_position = get_player_position()
	if (player_position != null):
		if (position.distance_to(player_position) <= detection_range):
			move_towards_player(player_position, delta)
			return
	move_randomly(delta)
	move_and_slide()

func move_randomly(delta):
	speed = NORMAL_SPEED
	$SlimeSprite.speed_scale = 1
	position += direction * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
func move_towards_player(player_position: Vector2, delta: float):
	speed = RUN_SPEED
	$SlimeSprite.speed_scale = 2
	direction = (player_position - position).normalized()
	position += direction * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	
func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 10

func get_player_position():
	if get_parent() != null:
		var parent = get_parent()
		if parent.has_node("Player"):
			return parent.get_node("Player").position
	return null
