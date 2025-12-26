class_name ReplaceOnAreaEnetered
extends ReplaceScene

@export var enter_area : Area2D
@export var damage_amount : int = 200
# Called w the node enters the scene tree for the first time.
func _ready() -> void:
	enter_area.connect("body_entered",_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(p_body: Node2D):
	replace()
	if p_body.has_method("take_damage")   :
		p_body.take_damage(damage_amount)
		print("detected")
	
