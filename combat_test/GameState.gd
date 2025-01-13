extends Node
var save_route = "user://save_data.save"
var FIRST_LEVEL = "bosque"
var level = FIRST_LEVEL

#Speed
@export var WALK_SPEED = 45 # How fast the player will move (pixels/sec).
@export var RUN_SPEED = 65
var speed = WALK_SPEED
#Health
@export var MAX_HEALTH = 10
var health = MAX_HEALTH
#Stamina
@export var MAX_STAMINA = 50
var stamina = MAX_STAMINA
var STAMINA_REGEN = 0.20 #porcentaje de la barra de estamina que regenera por segundo
var stamina_regen = STAMINA_REGEN
@export var RUN_STAMINA_COST_SEC = 10
var stamina_run_cost_sec = RUN_STAMINA_COST_SEC
@export var ATTACK_STAMINA_COST = 15
var attack_stamina_cost = ATTACK_STAMINA_COST
@export var can_regen_stamina = true
@export var STAMINA_REGEN_TIMER_TIMEOUT = 0.3

# Note: This can be called from anywhere inside the tree. This function is
# path independent.
# Go through everything in the persist category and ask them to return a
# dict of relevant variables.

#
#var nodo_player = nodo_main.nodo_player

func save_game():
	var save_file = FileAccess.open(save_route, FileAccess.WRITE)
	if !save_file:
		print("Error al abrir el archivo para guardar.")
		return

	var save_data = {}
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	print(save_nodes)
	for node in save_nodes:
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue
		
		var node_data = node.call("save")
		if typeof(node_data) != TYPE_DICTIONARY:
			print("El nodo '%s' devolvió datos inválidos, omitido." % node.name)
			continue
		
		save_data[node.name] = node_data

	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	print("Juego guardado exitosamente.")

# Note: This can be called from anywhere inside the tree. This function
# is path independent.
func load_game():
	# Abrir el archivo JSON
	var json = FileAccess.open(save_route, FileAccess.READ)
	#si no hay guardado no hace nada porque ya se ha delcarada el primer nivel
	if (json == null):
		return

	var json_text = json.get_as_text()
	var data = JSON.parse_string(json_text)
	
	var main_data = data["main"]
	var player_data = data["Player"]
	print(player_data)
	level = main_data["level"]
	
	WALK_SPEED = player_data["WALK_SPEED"]
	RUN_SPEED = player_data["RUN_SPEED"]
	MAX_HEALTH = player_data["MAX_HEALTH"]
	health = player_data["health"]
	MAX_STAMINA = player_data["MAX_STAMINA"]
	stamina = player_data["MAX_STAMINA"]
	stamina_regen = player_data["stamina_regen"]
	RUN_STAMINA_COST_SEC = player_data["RUN_STAMINA_COST_SEC"]
	attack_stamina_cost = player_data["attack_stamina_cost"]
	STAMINA_REGEN_TIMER_TIMEOUT = player_data["STAMINA_REGEN_TIMER_TIMEOUT"]
	
	#var nodo_main = preload("res://scenes/main.tscn").instantiate()
	#nodo_main.level = level
	#get_tree().change_scene()
	
	

	
