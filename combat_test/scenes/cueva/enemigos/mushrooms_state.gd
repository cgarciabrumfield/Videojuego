extends Node

var is_nervous = false
var is_fleeing = false
var nervous_duration = 15.0  # Tiempo en segundos para calmarse
var nervous_timer = 0.0    # Temporizador acumulado

func make_nervous():
	if not is_nervous:  # Solo activa si no están ya nerviosos
		is_nervous = true
		is_fleeing = true
		nervous_timer = nervous_duration  # Reinicia el temporizador

func relax():
	nervous_timer = 0.0
	is_nervous = false
	is_fleeing = false

func _process(delta: float):
	if is_nervous:
		nervous_timer -= delta  # Reduce el tiempo restante
		if nervous_timer <= nervous_duration - 3.0:
			is_fleeing = false
		if nervous_timer <= 0.0:
			is_nervous = false  # Calma a los enemigos
			nervous_timer = 0.0  # Reinicia el temporizador por seguridad
