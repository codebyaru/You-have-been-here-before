@icon("../icons/juicy_player_icon.svg")

extends Juicy_effect
class_name Juicy_effect_quit

# Ye function tab chalega jab Juicy Player is node tak pahuchega
func Play():
	# Game ko tata bye bye bolne ka command
	get_tree().quit()
