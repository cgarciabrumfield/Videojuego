class_name Hurtbox
extends Area2D

var knockback_direction
var knockback_strengh
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_mask = 2
	collision_layer = 0
	connect("area_entered", self._on_area_entered)

# Cuando algo entra en la hurtbox, se comprueba que sea una hitbox y que no sea la nuestra
func _on_area_entered(hitbox) -> void:
	if hitbox == null || hitbox is not Player_Hitbox || hitbox.owner == owner:
		if hitbox.owner is Bullet:
			if !hitbox.owner.was_parried:
				return
		else:
			return
	# Una vez comprobado, si el dueño de la hurtbox tiene una funcion take_damage, recibe el daño
	# que estuviera asociado a la hitbox con la que colisionó
	if owner.has_method("take_damage"):
		knockback_direction = (owner.global_position - hitbox.global_position).normalized()
		knockback_strengh = hitbox.knockback
		owner.take_damage(hitbox.damage, knockback_direction, knockback_strengh)
	else:
		print("Cebolleta")
