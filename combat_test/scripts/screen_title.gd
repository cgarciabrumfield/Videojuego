extends Control

@onready var knight_sprite = $background/knight_sprite

func _ready():
	knight_sprite.play()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
