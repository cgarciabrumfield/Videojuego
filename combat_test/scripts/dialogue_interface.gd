extends Control

@onready var animation_player = $dialogue_animation
@onready var dialogue = $background/dialogue
var anim_duration = 3.0
@export var char_show_percent = 0
var text_length = 320
var CHARACTERS_PER_SECOND = 48.0
var AVERAGE_LENGTH = 65.0
var FONT_SIZE_DEFAULT = 90

# Se tiene que llamar antes de cambiar de escena para que tenga los datos
func get_dialogue(dialogue_file_path: String):
	var file = FileAccess.open(dialogue_file_path, FileAccess.READ)
	var content = file.get_as_text(true)
	dialogue.add_text(content)
	text_length = len(content) 
	print(text_length)
	# tamaño de fuente variable
	var font_size = (1.0/(text_length/AVERAGE_LENGTH)) * FONT_SIZE_DEFAULT
	dialogue.add_theme_font_size_override("normal_font_size", font_size)
	# (probar) Si queremos dividir el texto en vez de usar el scroll:
	# var lines = content.split("\n") #o dividir con puntos

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_dialogue('res://dialogues/prueba.txt')
	animation_player.speed_scale = float(CHARACTERS_PER_SECOND/text_length)
	animation_player.play("show_text")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	dialogue.set_visible_characters(char_show_percent*text_length)
	print(char_show_percent*text_length)
