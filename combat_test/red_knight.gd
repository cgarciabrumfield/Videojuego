extends Area2D
@export var is_attacking = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Input.is_action_pressed("left"):
		$AnimationPlayer.play("attack_left")
	if Input.is_action_pressed("down"):
		$AnimationPlayer.play("attack_down")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
