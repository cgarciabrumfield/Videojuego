class_name Player_Hurtbox
extends Area2D

# Variables según la hitbox que golpee
var damage
var knockback_direction
var knockback_strengh
var attacker
var can_be_parried
var can_be_blocked

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
		damage = hitbox.damage
		knockback_direction = (owner.global_position - hitbox.global_position).normalized()
		knockback_strengh = hitbox.knockback
		attacker = hitbox.owner
		can_be_parried = hitbox.can_be_parried
		can_be_blocked = hitbox.can_be_blocked
		owner.take_damage(damage, knockback_direction,
		 knockback_strengh, attacker, can_be_parried, can_be_blocked)
		
func _on_area_exited(hitbox) -> void:
	if hitbox == last_hitbox:
		inside = false
		timer.stop()

func _on_timer_timeout():
	timer.start()
	knockback_direction = (owner.global_position - last_hitbox.global_position).normalized()
	knockback_strengh = last_hitbox.knockback
	can_be_parried = last_hitbox.can_be_parried
	can_be_blocked = last_hitbox.can_be_blocked
	owner.take_damage(last_hitbox.damage, knockback_direction,
	 knockback_strengh, last_hitbox.owner, can_be_parried, can_be_blocked)
