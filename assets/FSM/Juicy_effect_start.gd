extends Juicy_effect
class_name Juicy_effect_start

# Inspector mein Game Scene select karne ke liye
@export_file("*.tscn") var game_scene_path: String

func Play():
	# 1. Check agar path khali toh nahi hai
	if game_scene_path == "":
		print("[Error] Game Scene Path is empty in Inspector!")
		return
	
	# 2. Global Reset (Jo tumhare purane code mein tha)
	Global.current_level = 2 
	
	# 3. Transition Trigger
	# Ye tumhare TransitionScreen singleton ko call karega
	TransitionScreen.transition_to(game_scene_path)
