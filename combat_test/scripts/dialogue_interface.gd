extends Control

@onready var animation = $dialogue_animation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animation.play("dialogue_animation")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
