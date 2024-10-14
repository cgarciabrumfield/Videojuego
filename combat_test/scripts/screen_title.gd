extends Control

@onready var knight_sprite = $knight_sprite

func _ready():
	knight_sprite.play("iddle_down")

func _on_start_button_pressed() -> void:
	await get_tree().create_timer(0.2).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	pass # Replace with function body.


func _on_quit_button_pressed():
	if get_tree() != null:
		get_tree().quit()
	else:
		queue_free()
