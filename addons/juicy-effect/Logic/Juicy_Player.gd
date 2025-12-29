@icon("../icons/juicy_player_icon.svg")

extends Node
class_name Juicy_player

signal juice_play()

@export var autoplay : bool
@export var  press_label: Label
# Called when the node enters the scene tree for the first time.
func _ready():
	if autoplay:
		Play()

func Play():
	
	juice_play.emit()
	for child in get_children():
		if child is Juicy_effect:
			var juicy : Juicy_effect = child
			child.Play()
			if child.stopper :
				await child.on_stop
			

func Stop():
	for child in get_children():
		if child is Juicy_effect:
			var juicy : Juicy_effect = child
			child.Stop()

			


func _on_item_button_down() -> void:
	pass # Replace with function body.
