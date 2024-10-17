extends ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = owner.stamina * 100 / owner.MAX_STAMINA
	show_percentage = false

func update():
	value = owner.stamina * 100 / owner.MAX_STAMINA
