extends Control

func _ready():
	# Play intro music when scene loads
	AudioManager.play_music("res://Audio/Music/intro_music. mp3", -5.0)

# When player clicks "Start Game" button
func _on_start_button_pressed():
	AudioManager.fade_out_music(0.5)  # Fade out over 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://Scenes/lvl_2.tscn")

# When player clicks "Quit" button
func _on_quit_button_pressed():
	get_tree().quit()
 	 	
