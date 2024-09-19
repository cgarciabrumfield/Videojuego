class_name Hurtbox
extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_mask = 2
	collision_layer = 0
	connect("area_entered", self._on_area_entered)
	
#Cuando algo entra en la hurtbox, se comprueba que sea una hitbox y que no sea la nuestra
func _on_area_entered(area: Area2D) -> void:
	# Verificar si el área entrante es una Player_Hitbox
	if area is Player_Hitbox:
		var hitbox: Player_Hitbox = area as Player_Hitbox
		# Verificar que la hitbox no sea nula y no pertenezca al mismo dueño
		if hitbox == null or hitbox.owner == owner:
			return
		# Si el dueño de la hurtbox tiene una función take_damage, recibe el daño de la hitbox
		if owner.has_method("take_damage"):
			owner.take_damage(hitbox.damage)
