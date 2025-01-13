extends Node

var esqueletos_vivos = 0

func add_skeleton():
	esqueletos_vivos += 1

func faint_skeleton():
	esqueletos_vivos -= 1
	
func check_skeletons():
	if esqueletos_vivos <= 0:
		return 0
	return esqueletos_vivos
