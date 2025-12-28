extends Node

# --- CONSTANTS ---
const GAME_LEVEL_CAP := 10 

# --- GAME STATE ---
var current_level := 2
var current_level_id : String = "lvl2" # Make sure this defaults to your starting level string
var loop_count := 0

# --- NEW: PLAYER PROGRESS ---
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
	"lvl5": "res://Scenes/lvl_6.tscn",
	"lvl6": "res://Scenes/lvl_7.tscn",
	"lvl7": "res://Scenes/lvl_8.tscn",
	"lvl8": "res://Scenes/lvl_9.tscn",
	"lvl9": "res://Scenes/lvl_10.tscn",
	"lvl10": "res://Scenes/lvl_2.tscn" 
}

# --- SAVE SYSTEM VARIABLES ---
# We store these temporarily when loading so the Player can grab them inside _ready
var load_health = -1
var load_mana = -1
var load_position = Vector2.ZERO
var is_loading_save = false # Helps UI know if we are loading

# --- TRANSITION LOGIC ---
func proceed_to_next_level():
	print("[GLOBAL] Attempting to advance from:", current_level_id)
	
	if next_level_scenes.has(current_level_id):
		var next_scene_path = next_level_scenes[current_level_id]
		
		# Update Levels
		if current_level < GAME_LEVEL_CAP:
			current_level += 1
		else:
			current_level = 2 
			loop_count += 1
			
		# Update ID based on logic (Simple example, adjust as needed)
		current_level_id = "lvl" + str(current_level)
		
		

		print("[GLOBAL] Transitioning to:", next_scene_path)
		# NOTE: Assuming TransitionScreen is your autoload/singleton for fading
		TransitionScreen.transition_to(next_scene_path)
	else:
		print("[GLOBAL] ERROR: No next scene defined for", current_level_id)

# ---------------------------------------------------------
# --- SAVE & LOAD SYSTEM ---
# ---------------------------------------------------------
func save_game():
	# 1. Gather Data
	var save_data = {
		"current_level": current_level,
		"current_level_id": current_level_id,
		"max_level": max_level,
		"loop_count": loop_count,
		"scene_path": get_tree().current_scene.scene_file_path,
		"beacon_access": beacon_access_count,
		"completed_levels": completed_levels,
		# Player specific data
		"player_pos_x": player_ref.global_position.x if player_ref else 0,
		"player_pos_y": player_ref.global_position.y if player_ref else 0,
		"player_hp": player_ref.current_health if player_ref else 500,
		"player_mana": player_ref.current_mana if player_ref else 300
	}
	
	# 2. Write to file
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	
	# --- ERROR CHECKING ---
	if file == null:
		print("[ERROR] Could not create save file! Error Code: ", FileAccess.get_open_error())
		return

	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close() # Good practice to close explicitely
	
	# --- PRINT REAL PATH ---
	var real_path = ProjectSettings.globalize_path("user://savegame.save")
	print("[GLOBAL] Game Saved Successfully at: ", real_path)
	
	
func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		print("[GLOBAL] No save file found.")
		return

	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result == OK:
		var data = json.get_data()
		
		# 1. Load Global Variables
		current_level = data.get("current_level", 2)
		current_level_id = data.get("current_level_id", "lvl2")
		max_level = data.get("max_level", 1)
		loop_count = data.get("loop_count", 0)
		beacon_access_count = data.get("beacon_access", {})
		completed_levels = data.get("completed_levels", {})
		
		# 2. Store Player Stats Temporarily (Player will grab these in _ready)
		load_position = Vector2(data.get("player_pos_x", 0), data.get("player_pos_y", 0))
		load_health = data.get("player_hp", 500)
		load_mana = data.get("player_mana", 300)
		
		is_loading_save = true # Turn this flag ON so UI knows to be silent
		
		# 3. Change Scene
		var scene_path = data.get("scene_path", "")
		if scene_path != "":
			# Use your transition or standard change_scene
			TransitionScreen.transition_to(scene_path)
			# Or if TransitionScreen isn't available: get_tree().change_scene_to_file(scene_path)
		
		print("[GLOBAL] Game Loaded. Max Level is now: ", max_level)
