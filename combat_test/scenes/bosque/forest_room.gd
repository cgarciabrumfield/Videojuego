extends Node2D

var connected_rooms = {
	Vector2(1, 0): null,
	Vector2(-1, 0): null,
	Vector2(0, 1): null,
	Vector2(0, -1): null
}

var number_of_connections = 0

var num_enemies
var opened_doors = false

#Lista de booleanos Norte Sur Este Oeste
var ya_explorada

@onready var door_left = $Left_wall/left_door/left_door_area
@onready var door_left_sprite = $Left_wall/left_sprite
@onready var connected_left = connected_rooms.get(Vector2(-1,0)) != null

@onready var door_right = $Right_wall/right_door/right_door_area
@onready var door_right_sprite = $Right_wall/right_sprite
@onready var connected_right = connected_rooms.get(Vector2(1,0)) != null

@onready var door_top = $Top_wall/top_door/top_door_area
@onready var door_top_sprite = $Top_wall/top_sprite
@onready var connected_top = connected_rooms.get(Vector2(0,-1)) != null

@onready var door_bottom = $Bottom_wall/bottom_door/bottom_door_area
@onready var door_bottom_sprite = $Bottom_wall/bottom_sprite
@onready var connected_bottom = connected_rooms.get(Vector2(0,1)) != null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_walls()

func _process(delta: float) -> void:
	num_enemies = $enemigos.get_child_count()
	if num_enemies == 0:
		open_doors()

func generate_walls():
	door_left.disabled = false
	door_left_sprite.frame = 0
	door_right.disabled = false
	door_right_sprite.frame = 0
	door_top.disabled = false
	door_top_sprite.frame = 0
	door_bottom.disabled = false
	door_bottom_sprite.frame = 0
	
func visited(visitado: bool):
	if visitado:
		open_doors()
	else:
		generate_enemies()

func generate_enemies():
	print("Enemigos generados")

func open_doors():
	if opened_doors:
		return
	opened_doors = true
	print("Puertas abiertas")
	if connected_bottom:
		door_bottom.disabled = true
		door_bottom_sprite.frame = 1
	if connected_left:
		door_left.disabled = true
		door_left_sprite.frame = 1
	if connected_right:
		door_right.disabled = true
		door_right_sprite.frame = 1
	if connected_top:
		door_top.disabled = true
		door_top_sprite.frame = 1

func _on_bottom_transition_body_entered(body: Node2D) -> void:
	print("Bottom area entered")
	get_parent().cambiar_sala(Vector2(0,1))

func _on_left_transition_body_entered(body: Node2D) -> void:
	print("Left area entered")
	get_parent().cambiar_sala(Vector2(-1,0))

func _on_right_transition_body_entered(body: Node2D) -> void:
	print("Right area entered")
	get_parent().cambiar_sala(Vector2(1,0))

func _on_top_transition_body_entered(body: Node2D) -> void:
	print("Top area entered")
	get_parent().cambiar_sala(Vector2(0,-1))
