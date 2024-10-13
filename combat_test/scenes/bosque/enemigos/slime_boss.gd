extends CharacterBody2D

@export var maxHealth = 15
@export var health = maxHealth
@export var is_hurt = false
var screen_size
@export var jump_attack_triggered = false
const NORMAL_SPEED = 35
const RUN_SPEED = 35
@export var speed = NORMAL_SPEED # Velocidad a la que se moverá el limo
var direction_change_interval: float = 2.0 # Tiempo para cambiar de dirección
var timer: float = 0.0 # Timer para controlar el cambio de dirección
var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial
var normalized_Y_pos # Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
#Sonidos
@onready var hurt_VFX = $hurt_vfx
@onready var healthbar = $CanvasLayer/Healthbar
@onready var damagebar = $CanvasLayer/Healthbar/Damagebar
@onready var timer_vida = $CanvasLayer/Healthbar/Timer
# Físicas
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_duration: float = 0.2  # Duración del retroceso en segundos
var knockback_timer: float = 0.0
#Slimes invocados
var slime_scene = preload("res://scenes/bosque/enemigos/slime.tscn")
var summoned_slimes = 0
var max_slimes = 3
var segunda_fase_iniciada = false
@onready var summon_slime_cooldown = $summon_slime_cooldown
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	health = maxHealth
	screen_size = get_viewport_rect().size
	position = Vector2(0,0)
	
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
	if health * 2 <= maxHealth && !segunda_fase_iniciada:
		segunda_fase_iniciada = true
		summon_slime_cooldown.start()
		
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
		if $jump_attack_timer.is_stopped():
			jump_attack()
		
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
		move_towards_player(player_position, delta)
		return

func move_randomly(delta):
	speed = NORMAL_SPEED
	$SlimeSprite.speed_scale = 1
	position += direction * speed * delta
	move_and_slide()
	
func move_towards_player(player_position: Vector2, delta: float):
	if !jump_attack_triggered:
		speed = RUN_SPEED
	$SlimeSprite.speed_scale = 2
	direction = (player_position - position).normalized()
	position += direction * speed * delta
	move_and_slide()
	
func depth_control():
	# Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 10

func get_player_position():
	return _find_player(get_tree().get_root())
	
func _find_player(node):
	if node.name == "Player":
		return node.position
		
	for child in node.get_children():
		var position_jugador = _find_player(child)
		if position_jugador != null:
			return position_jugador
	return null

func jump_attack():
	jump_attack_triggered = true
	$jump_attack_timer.start()

func _on_jump_attack_timer_timeout() -> void:
	$jump_attack_timer.stop()
	$AnimationPlayer.play("jump_attack")

func summon_slime():
	if summoned_slimes < max_slimes:
		print("Slime summoned")
		var new_slime = slime_scene.instantiate() # Instancia la escena
		get_parent().add_child(new_slime)
		new_slime.position = position + Vector2(randi_range(-10,10), randi_range(-10, 10))
		new_slime.detection_range = 1000
		var tween = create_tween()
		new_slime.scale = Vector2(0,0)
		tween.tween_property(new_slime, "scale", Vector2(1,1), 0.5)
		# Conectar la señal "tree_exited" para detectar cuando el slime muere
		new_slime.connect("tree_exited", self._on_slime_died)
		summoned_slimes += 1
	else:
		print("Max slimes reached")

func _on_slime_died():
	summoned_slimes -= 1
	print("Slime died, total summoned slimes:", summoned_slimes)
	
func _on_summon_slime_cooldown_timeout() -> void:
	if $AnimationPlayer.current_animation == "jump_attack":
		await $AnimationPlayer.animation_finished
	summon_slime()
	summon_slime_cooldown.start()
