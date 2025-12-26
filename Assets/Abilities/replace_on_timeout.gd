class_name  ReplaceOnTimeout
extends ReplaceScene
@export var replace_timer: Timer

func _ready() -> void:
	replace_timer.connect("timeout",_on_timeout)
	print(replace_damage," ",replace_scale)
	
func _on_timeout():
	replace()
