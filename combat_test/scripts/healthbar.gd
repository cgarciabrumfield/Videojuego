extends ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	value = owner.health * 100 / owner.MAX_HEALTH
	show_percentage = false

func update():
	value = owner.health * 100 / owner.MAX_HEALTH
