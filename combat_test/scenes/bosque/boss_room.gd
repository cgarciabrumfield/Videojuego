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
@onready var enemigos = $enemigos
@onready var ground = $Ground
var nodo_enemigos
var nodo_props

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
var level
func _ready() -> void:
	level = get_parent().level
	if level != "bosque":
		$Left_wall/left_sprite_extra.hide()
		$Right_wall/right_sprite_extra.hide()
	generate_walls()
	var random_number_prop_file = randi_range(1, count_prop_distribution_scenes())
	print(random_number_prop_file)
	var ruta_props: String = ("res://scenes/" + level + "/salas/distribuciones_props/props_" + 
	str(random_number_prop_file) + ".tscn")
	print(ruta_props)
	nodo_props = "props_" + str(random_number_prop_file)
	add_child(load(ruta_props).instantiate())
	
	ground.texture = load(str("res://scenes/" + level + "/salas/suelos/ground_" + 
	str(randi_range(1, count_ground_files()))) + ".png")
	
func _process(_delta: float) -> void:
	num_enemies = count_enemies()
	print(num_enemies)
	if num_enemies == 0:
		open_doors()

func generate_walls():
	door_left.disabled = false
	if connected_left:
		door_left_sprite.frame = 0
	else:
		door_left_sprite.frame = 2
	door_right.disabled = false
	if connected_right:
		door_right_sprite.frame = 0
	else:
		door_right_sprite.frame = 2
	door_top.disabled = false
	if connected_top:
		door_top_sprite.frame = 0
	else:
		door_top_sprite.frame = 2
	door_bottom.disabled = false
	if connected_bottom:
		door_bottom_sprite.frame = 0
	else:
		door_bottom_sprite.frame = 2
	
func open_doors():
	if opened_doors:
		return
	opened_doors = true
	#print("Puertas abiertas")
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
	Globals.get_mejoras_node(self).sube_nivel()
	LevelUpSfx.play_sfx()

func _on_bottom_transition_body_entered(_body: Node2D) -> void:
	print("Bottom area entered")
	get_parent().cambiar_sala(Vector2(0,1))

func _on_left_transition_body_entered(_body: Node2D) -> void:
	print("Left area entered")
	get_parent().cambiar_sala(Vector2(-1,0))

func _on_right_transition_body_entered(_body: Node2D) -> void:
	print("Right area entered")
	get_parent().cambiar_sala(Vector2(1,0))

func _on_top_transition_body_entered(_body: Node2D) -> void:
	print("Top area entered")
	get_parent().cambiar_sala(Vector2(0,-1))

func count_ground_files() -> int:
	var dir =  DirAccess.open("res://scenes/" + level + "/salas/suelos/")
	var count = 0
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("ground_") and not file_name.ends_with("import"):
				count += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open directory")
		FileAccess.get_open_error()
	return count

func count_prop_distribution_scenes() -> int:
	var dir =  DirAccess.open("res://scenes/" + level + "/salas/distribuciones_props/")
	var count = 0
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.begins_with("props_") and file_name.ends_with(".tscn"):
				count += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("Failed to open directory")
		FileAccess.get_open_error()
	return count
	
func count_enemies() -> int:
	var grandchild_count = 0
	for child in enemigos.get_children():
		for enemigo in child.get_children():
			if enemigo is CharacterBody2D:
				grandchild_count += 1
	return grandchild_count
