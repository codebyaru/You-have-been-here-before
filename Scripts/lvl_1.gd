extends Node2D

# Inspector mein yahan 'lvl2.tscn' (Game Scene) drag-drop karna
@export_file("*.tscn") var next_level_path: String 

func _ready():
	# 1. Music Play (Optional)
	# AudioManager.play_music("res://audio/music/intro_theme.mp3")

	print("[LVL 1] Starting Intro Sequence...")

	# 2. Dialogic Signal Connect karo
	Dialogic.timeline_ended.connect(_on_dialogue_finished)
	
	# 3. Start Timeline
	Dialogic.start("Start_scenes")

# --- SIGNAL HANDLER ---
func _on_dialogue_finished():
	print("[LVL 1] Intro Finished. Loading Game...")
	
	# 4. Cleanup (Signal disconnect taaki memory leak na ho)
	Dialogic.timeline_ended.disconnect(_on_dialogue_finished)
	
	# 5. Game Setup
	Global.current_level = 2 # Ab Level 2 (Gameplay) start hoga
	
	# 6. Change Scene
	if next_level_path:
		TransitionScreen.transition_to(next_level_path)
	else:
		print("❌ ERROR: Inspector mein 'Next Level Path' set nahi kiya hai!")
