extends Control

@onready var animation_player = $dialogue_animation
@onready var dialogue = $background/dialogue
var anim_duration = 3.0
@export var char_show_percent = 0
var text_length = 100
var CHARACTERS_PER_SECOND = 48

func get_dialogue(dialogue_text: String):
	if (dialogue_text != null):
		dialogue.text = dialogue_text
		text_length = dialogue.text.length()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation_player.speed_scale = CHARACTERS_PER_SECOND/text_length
	animation_player.play("new_animation")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	dialogue.set_visible_characters(char_show_percent*text_length)
