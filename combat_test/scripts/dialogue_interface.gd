class_name Dialogue_Interface
extends Control

@onready var animation_player = $dialogue_animation
@onready var dialogue = $background/dialogue
var anim_duration = 3.0
@export var char_show_percent = 0
var text_length = 0
var CHARACTERS_PER_SECOND = 48.0
var AVERAGE_LENGTH = 65.0
var FONT_SIZE_DEFAULT = 25
var dialogo_ruta = "res://dialogos.json"
var time = 0

# Se tiene que llamar antes de cambiar de escena para que tenga los datos
func get_dialogue(nombre_sala: String):
	var json_text = FileAccess.open(dialogo_ruta, FileAccess.READ).get_as_text()
	
	var data = JSON.parse_string(json_text)
	var dialogo = data[nombre_sala]
	var content = dialogo["contenido"]
	
	dialogue.clear()
	dialogue.add_text(content)
	text_length = len(content)
	print(text_length)
	# tamaño de fuente variable
	#var font_size = (1.0/(text_length/AVERAGE_LENGTH)) * FONT_SIZE_DEFAULT
	#dialogue.add_theme_font_size_override("normal_font_size", font_size)
	
	animation_player.speed_scale = float(CHARACTERS_PER_SECOND/text_length)
	animation_player.play("show_text")
	time = 0
	self.visible = true
	set_process(true)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = false
	set_process(false)
	pass
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	dialogue.set_visible_characters(char_show_percent*text_length)
	
	time += _delta
	if time >= 5:
		dialogue.clear()
		self.visible = false
		set_process(false)
	#print(char_show_percent*text_length)
	
