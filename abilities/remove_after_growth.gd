extends Node

@export var grow_over_time : GrowOverTime
@export var queue_free_target : Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	grow_over_time.connect("growing_changed",_on_growing_changed)

func _on_growing_changed(p_status: bool):
	
	if (p_status == false):
		queue_free_target.queue_free()
