extends Node
var save_route = "user://save_data.save"
var level = "bosque"

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
	var json_text = FileAccess.open(save_route, FileAccess.READ).get_as_text()

	var data = JSON.parse_string(json_text)
	
	var main_data = data["main"]
	var player_data = data["Player"]
	print(player_data)
	level = main_data["level"]
	
	#var nodo_main = preload("res://scenes/main.tscn").instantiate()
	#nodo_main.level = level
	#get_tree().change_scene()
	
	

	
