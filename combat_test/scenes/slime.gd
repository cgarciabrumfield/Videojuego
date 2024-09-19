extends Area2D
var rng = RandomNumberGenerator.new()
@export var life = 4
var is_hurt = false
var screen_size
const SPEED = 50
@onready var timer_vida = $Timer #Timer que controla cuando se actualiza la barra de vida
@export var speed = SPEED #Velocidad a la que se moverá el limo
var direction_change_interval: float = 2.0 #Tiempo para cambiar de dirección
var timer: float = 0.0 #Timer para controlar el cambio de dirección
var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial
var normalized_Y_pos #Posicion en el eje Y normalizada entre 0 y 1 para el calculo de profundidad asociado
@onready var hurt_VFX = $hurt_vfx

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	position = Vector2(rng.randi_range(0, screen_size.x), rng.randi_range(0, screen_size.y))
	$Healthbar_red.frame = life
	$Healthbar_trans.frame = life

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_hurt == false: #Mientras no esté siendo herido, el limo se mueve normal
		$SlimeSprite.play("default")
	move(delta)
	depth_control()
	#Actualiza el timer para cambiar la dirección
	timer -= delta
	if timer <= 0:
		change_direction()

#Función para cambiar la dirección aleatoriamente
func change_direction():
	#Genera un nuevo vector aleatorio con valores entre -1 y 1
	direction = Vector2(randi_range(-1, 1), randi_range(-1, 1)).normalized()
	#Reinicia el timer
	timer = direction_change_interval

#Literalmente lo mismo que la del caballero pero mas facil. Id a mirar los comentarios en knight.gd
func take_damage(ammount: int) -> void:
	hurt_VFX.play()
	life -= ammount
	speed = 0
	timer_vida.start()
	$Healthbar_trans.frame = life
	if life <= 0:
		kill()
	elif is_hurt == false:  #Verifica que el enemigo no esté ya en animación de daño
		$AnimationPlayer.play("damage")
		
func _on_timer_timeout() -> void:
	$Healthbar_red.frame = life
	timer_vida.stop()

#Función de me voy con San Pedro del limo
func kill():
	$AnimationPlayer.play("death")
	await get_tree().create_timer(0.9).timeout
	queue_free() #Importante esto ojo aquí. Esto sirve para eliminar al limo de la escena
	
func move(delta):
	#Mueve al limo en la dirección aleatoria
	position += direction * speed * delta
	position = position.clamp(Vector2.ZERO, screen_size)

func depth_control():
	#Actualizamos el valor de profundidad del eje z según la altura del personaje en el eje y
	normalized_Y_pos = position.y / screen_size.y
	#Esta cosa extraña es para poner el valor de z en el rango posible según donde se ejecute el juego
	z_index = normalized_Y_pos * 2*RenderingServer.CANVAS_ITEM_Z_MAX + RenderingServer.CANVAS_ITEM_Z_MIN
