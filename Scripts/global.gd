extends Node

# --- CONSTANTS ---
const MAX_LEVEL := 10

# --- GAME STATE ---
var current_level := 2
var current_level_id :String = ""
var loop_count := 0

# --- PLAYER & WORLD STATE (Ye missing thay, wapas aa gaye) ---
var player_ref: CharacterBody2D = null
var respawn_position: Vector2 = Vector2.ZERO
var dialogue_playing := false

# --- DATA STORAGE ---
var beacon_access_count := {}   # Example: { "lvl2_beacon_1": 1 }
var completed_levels := {}      # Example: { "lvl2": true }

# --- SCENE CONFIGURATION ---
# Key = Current Level ID, Value = Next Scene Path
var next_level_scenes = {
	"lvl2": "res://Scenes/lvl_3.tscn",
	"lvl3": "res://Scenes/lvl_5.tscn",
	"lvl5": "res://Scenes/lvl_7.tscn",
	"lvl7": "res://Scenes/lvl_9.tscn",
	"lvl9": "res://Scenes/lvl_10.tscn",
	# ... aage ke levels yahan add karna ...
	
	# Loop Logic ke liye placeholder path (baad mein condition lagenge)
	"lvl10": "res://Scenes/lvl_2.tscn" 
}

# --- TRANSITION LOGIC ---
func proceed_to_next_level():
	print("[GLOBAL] Attempting to advance from:", current_level_id)
	
	# --- FUTURE LOOP LOGIC ---
	# Yahan hum check karenge:
	# if current_level == 10 and condition_failed:
	#     current_level = 2
	#     TransitionScreen.transition_to("res://Scenes/lvl_2.tscn")
	#     return
	
	# --- NORMAL TRANSITION ---
	if next_level_scenes.has(current_level_id):
		var next_scene_path = next_level_scenes[current_level_id]
		
		# Update Logic
		if current_level < MAX_LEVEL:
			current_level += 1
		else:
			# Loop case (Agar normal loop hua bina condition ke)
			current_level = 2 
			loop_count += 1
			
		# NOTE: current_level_id update mat karo yahan, 
		# kyunki wo naye level ke _ready() mein set hoga.
		
		print("[GLOBAL] Transitioning to:", next_scene_path)
		TransitionScreen.transition_to(next_scene_path)
		
	else:
		print("[GLOBAL] ERROR: No next scene defined for", current_level_id)
		# Fallback to Main Menu incase of error
		# TransitionScreen.transition_to("res://Scenes/MainMenu.tscn")
