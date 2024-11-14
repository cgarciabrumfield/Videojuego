extends Area2D
var screen_size
var normalized_Y_pos
var tree_sprite

# Se llama cuando el nodo entra en el árbol de la escena por primera vez.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	depth_control()
	tree_sprite = $Tree_sprite

# Control de profundidad (Z-index)
func depth_control():
	normalized_Y_pos = position.y / screen_size.y
	z_index = normalized_Y_pos * 90 + 10

func _on_body_entered(_body: Node2D) -> void:
	var tween = create_tween()
	tween.tween_property(tree_sprite, "modulate:a", 0.5, 0.3) # Transición a 0.5 de opacidad en 0.5 segundos

func _on_body_exited(_body: Node2D) -> void:
	var tween = create_tween()
	tween.tween_property(tree_sprite, "modulate:a", 1, 0.3) # Transición a 1 de opacidad en 0.5 segundos
