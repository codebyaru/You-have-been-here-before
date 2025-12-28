class_name Ability
extends Resource

func use(p_user: Node2D) -> bool :
	push_error("Virtual function - implemnet in child class")
	return false


func ability():
	pass
