class_name Player_Hurtbox
extends Area2D

var knockback_direction
var knockback_strengh
var timer = Timer.new()
var inside = false
var last_hitbox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_mask = 2
	collision_layer = 0
	connect("area_entered", self._on_area_entered)
	timer.connect("timeout", self._on_timer_timeout)
	timer.wait_time = get_parent().inmune_time  # Duración del temporizador en segundos
	timer.one_shot = true  # Para que se ejecute solo una vez
	add_child(timer)  # Añadir el Timer como hijo del nodo actual	
	
func _process(delta: float) -> void:
	pass
#Cuando algo entra en la hurtbox, se comprueba que sea una hitbox y que no sea la nuestra
func _on_area_entered(hitbox) -> void:
	if hitbox == null || hitbox is not Hitbox || hitbox.owner == owner:
		return
	#Una vez comprobado, si el dueño de la hurtbox tiene una funcion take_damage, recibe el daño
	# que estuviera asociado a la hitbox con la que colisionó
	if owner.has_method("take_damage"):
		last_hitbox = hitbox
		inside = true
		timer.start()
		knockback_direction = (owner.global_position - hitbox.global_position).normalized()
		knockback_strengh = hitbox.knockback
		owner.take_damage(hitbox.damage, knockback_direction, knockback_strengh)
		print(hitbox.global_position)
		
func _on_area_exited(hitbox) -> void:
	if hitbox == last_hitbox:
		print("exited")
		inside = false
		timer.stop()

func _on_timer_timeout():
	timer.start()
	knockback_direction = (owner.global_position - last_hitbox.global_position).normalized()
	knockback_strengh = last_hitbox.knockback
	owner.take_damage(last_hitbox.damage, knockback_direction, knockback_strengh)
