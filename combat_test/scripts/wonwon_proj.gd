extends CharacterBody2D

var direction: Vector2 = Vector2.ZERO # Vector de dirección inicial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	velocity = _get_vector()
	print("Ready ejecutado")
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	move_and_slide()

func _get_vector() -> Vector2:
	return get_parent().direction_vector
