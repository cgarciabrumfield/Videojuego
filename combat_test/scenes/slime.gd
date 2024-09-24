extends CharacterBody2D
@export var life = 4
var is_hurt = false
var screen_size
const NORMAL_SPEED = 50
const RUN_SPEED = 80
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
@export var detection_range = 200
@onready var timer_vida = $Timer # Timer que controla cuando se actualiza la barra de vida
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@onready var hurt_VFX = $hurt_vfx
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	position = Vector2(randi_range(0, screen_size.x), randi_range(0, screen_size.y))
	$Healthbar_red.frame = life
	$Healthbar_trans.frame = life

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
	life -= ammount
	timer_vida.start()
	$Healthbar_trans.frame = life
	knockback_velocity = knockback_direction * knockback_strength
	knockback_timer = knockback_duration
	if life <= 0:
		kill()
	elif is_hurt == false:  # Verifica que el enemigo no esté ya en animación de daño
		$AnimationPlayer.play("damage")
		
func _physics_process(delta: float) -> void:
	if knockback_timer > 0:
		position += knockback_velocity * delta  # Actualiza la posición manualmente
		# Reducir suavemente la velocidad del retroceso
		knockback_velocity = lerp(knockback_velocity, Vector2.ZERO, 0.1)
		#Reduce el temporizador del retroceso
		knockback_timer -= delta
		
func _on_timer_timeout() -> void:
	$Healthbar_red.frame = life
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
	# Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	z_index = normalized_Y_pos * 2*RenderingServer.CANVAS_ITEM_Z_MAX + RenderingServer.CANVAS_ITEM_Z_MIN

func get_player_position():
	if get_parent() != null:
		var parent = get_parent()
		if parent.has_node("Player"):
			return parent.get_node("Player").position
	return null
