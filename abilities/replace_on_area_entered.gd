class_name ReplaceOnAreaEnetered
extends ReplaceScene

@export var enter_area : Area2D
@export var damage_amount : int = 200
@export var element_type : String = "physical" 

func _ready() -> void:
	if enter_area:
		enter_area.body_entered.connect(_on_body_entered)

func _on_body_entered(p_body: Node2D):
	replace() 
	
	if p_body.has_method("take_damage"):
		# USER IDEA: Check for the 'mahoraga' tag function
		if p_body.has_method("mahoraga"):
			# Mahoraga hai -> Type batao
			p_body.take_damage(damage_amount, element_type)
		else:
			# Normal enemy hai -> Sirf damage batao
			p_body.take_damage(damage_amount)
