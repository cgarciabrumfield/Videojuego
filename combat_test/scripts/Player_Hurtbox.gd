class_name Player_Hurtbox
extends Area2D

var knockback_direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_mask = 2
	collision_layer = 0
	connect("area_entered", self._on_area_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#Cuando algo entra en la hurtbox, se comprueba que sea una hitbox y que no sea la nuestra
func _on_area_entered(hitbox: Hitbox) -> void:
	if hitbox == null:
		return
	if hitbox.owner == owner:
		return
	#Una vez comprobado, si el dueño de la hurtbox tiene una funcion take_damage, recibe el daño
	# que estuviera asociado a la hitbox con la que colisionó
	if owner.has_method("take_damage"):
		knockback_direction = (owner.global_position - hitbox.global_position).normalized()
		owner.take_damage(hitbox.damage, knockback_direction)
		print(hitbox.global_position)
