extends Control

# --- CONFIGURATION ---
@export_file("*.tscn") var game_scene_path: String

# --- UI CONTAINERS (Drag these from your Scene Tree) ---
@export_group("Containers & Panels")
@export var intro_video: VideoStreamPlayer          # Assign: IntroVideo
@export var menu_ui: MarginContainer                # Assign: MarginContainer (The big one)
@export var button_container: VBoxContainer         # Assign: button_container
@export var load_panel: MarginContainer             # Assign: MarginContainer_LoadPanel
@export var save_slots_container: VBoxContainer     # Assign: VBoxContainer_SaveSlots
@export var save_slots_container_MC: MarginContainer  
# --- MAIN BUTTONS (Inside button_container) ---
# Drag these from inside your 'button_container'
@export_group("Main Buttons")
@export var btn_start: Button
@export var btn_load: Button
@export var btn_exit: Button

# --- LOAD PANEL BUTTONS ---
@export_group("Load Panel Buttons")
@export var btn_back: Button                        # Assign: go_back
@export var template_button: Button
func _ready() -> void:
	# 1. INITIAL STATE (Reset Visibility)
	# Even if you hid button_container in editor, we reset it here.
	intro_video.visible = true
	menu_ui.visible = false             # Hide the whole menu while video plays
	button_container.visible = true     # Ensure this is ON when menu appears
	load_panel.visible = false          # Ensure this is OFF initially
	
	# 2. START VIDEO
	intro_video.play()
	intro_video.finished.connect(_on_video_finished)
	
	# 3. CONNECT MAIN BUTTONS
	if btn_start: btn_start.pressed.connect(_on_start_pressed)
	if btn_exit: btn_exit.pressed.connect(_on_exit_pressed)
	if btn_load: btn_load.pressed.connect(_on_load_menu_pressed)
	
	# 4. CONNECT BACK BUTTON
	if btn_back: btn_back.pressed.connect(_on_back_pressed)

func _process(_delta: float) -> void:
	# Skip video on Space/Enter
	if intro_video.visible and Input.is_action_just_pressed("ui_accept"):
		_on_video_finished()

# ---------------------------------------------------------
# --- VIDEO LOGIC ---
# ---------------------------------------------------------
func _on_video_finished() -> void:
	intro_video.stop()
	intro_video.visible = false
	
	# Show the Main Menu
	menu_ui.visible = true
	
	# Double check states (Just in case)
	button_container.visible = true
	load_panel.visible = false

# ---------------------------------------------------------
# --- MAIN MENU ACTIONS ---
# ---------------------------------------------------------
func _on_start_pressed() -> void:
	if game_scene_path:
		btn_start.disabled = true
		# Reset Global variables for a new run
		Global.current_level = 2 
		TransitionScreen.transition_to(game_scene_path)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_load_menu_pressed() -> void:
	print("[MENU] Switching to Load Panel")
	# Swap Containers
	button_container.visible = false
	load_panel.visible = true
	
	# Refresh the list
	_refresh_save_files()

# ---------------------------------------------------------
# --- LOAD PANEL LOGIC ---
# ---------------------------------------------------------
func _on_back_pressed() -> void:
	# Swap Back
	load_panel.visible = false
	button_container.visible = true

func _refresh_save_files():
	print("[MENU] Refreshing Save Files (Template Mode)...")
	
	# 1. Clean up OLD buttons (But DON'T delete the template itself!)
	for child in save_slots_container.get_children():
		if child == template_button:
			continue # Skip the template, keep it safe
		child.queue_free()
	
	# 2. Check File
	if FileAccess.file_exists("user://savegame.save"):
		
		# --- DUPLICATE LOGIC ---
		# Create a copy of your stylish button
		var new_btn = template_button.duplicate()
		
		# Change Text
		new_btn.text = "Continue: Level " + str(Global.max_level)
		
		# Make it visible (because template is hidden)
		new_btn.visible = true
		
		# Connect the click signal
		new_btn.pressed.connect(_on_save_file_clicked)
		
		# Add it to the list
		save_slots_container.add_child(new_btn)
		
		print("[MENU] Button created from Template.")
		
	else:
		# Optional: You can also make a "No Save" template if you want
		var label = Label.new()
		label.text = "- No Save File Found -"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_slots_container.add_child(label)
		
		
func _on_save_file_clicked():
	print("[MENU] Loading Save File...")
	Global.load_game()
