extends Node

# --- CONSTANTS ---
# Renamed to avoid conflict with the new variable. 
# This is the limit where the game loops back.
const GAME_LEVEL_CAP := 10 

# --- GAME STATE ---
var current_level := 2
var current_level_id : String = ""
var loop_count := 0

# --- NEW: PLAYER PROGRESS ---
# This tracks the highest level reached (for UI Unlocks)
var max_level := 1

# --- PLAYER & WORLD STATE ---
var player_ref: CharacterBody2D = null
var respawn_position: Vector2 = Vector2.ZERO
var dialogue_playing := false

# --- DATA STORAGE ---
var beacon_access_count := {}   
var completed_levels := {}      

# --- SCENE CONFIGURATION ---
var next_level_scenes = {
	"lvl2": "res://Scenes/lvl_3.tscn",
	"lvl3": "res://Scenes/lvl_4.tscn",
	"lvl4": "res://Scenes/lvl_5.tscn",
	"lvl5": "res://Scenes/lvl_7.tscn",
	"lvl7": "res://Scenes/lvl_9.tscn",
	"lvl9": "res://Scenes/lvl_10.tscn",
	
	"lvl10": "res://Scenes/lvl_2.tscn" 
}

# --- TRANSITION LOGIC ---
func proceed_to_next_level():
	print("[GLOBAL] Attempting to advance from:", current_level_id)
	
	if next_level_scenes.has(current_level_id):
		var next_scene_path = next_level_scenes[current_level_id]
		
		# --- UPDATE LEVEL LOGIC ---
		if current_level < GAME_LEVEL_CAP:
			current_level += 1
		else:
			# Loop case: Reset current level, but keep max_level high!
			current_level = 2 
			loop_count += 1
			
		# --- NEW: UPDATE MAX LEVEL ---
		# Calculates which is bigger: current or old max
		
		
		print("[GLOBAL] Transitioning to:", next_scene_path)
		TransitionScreen.transition_to(next_scene_path)
		
	else:
		print("[GLOBAL] ERROR: No next scene defined for", current_level_id)
		
