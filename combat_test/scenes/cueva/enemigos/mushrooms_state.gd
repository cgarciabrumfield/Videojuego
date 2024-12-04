extends Node

var is_nervous = false
var nervous_duration = 5.0  # Tiempo en segundos para calmarse
var nervous_timer = 0.0    # Temporizador acumulado

func make_nervous():
	if not is_nervous:  # Solo activa si no están ya nerviosos
		is_nervous = true
		nervous_timer = nervous_duration  # Reinicia el temporizador

func update_timer(delta: float):
	if is_nervous:
		nervous_timer -= delta  # Reduce el tiempo restante
		if nervous_timer <= 0.0:
			is_nervous = false  # Calma a los enemigos
			nervous_timer = 0.0  # Reinicia el temporizador por seguridad
			print("Los enemigos se han calmado.")
