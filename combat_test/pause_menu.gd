extends Control

func _ready() -> void:
	$AnimationPlayer.play("RESET")

func _process(delta: float) -> void:
	listener()

#pauses and makes the pause menu visible
func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")

func pause():
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func listener():
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused:
		resume()
	if Input.is_action_just_pressed("pause2") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause2") and get_tree().paused:
		resume()

func _on_resume_pressed() -> void:
	resume()

func _on_quit_pressed() -> void:
	get_tree().quit()
