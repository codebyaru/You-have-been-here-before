extends MarginContainer

# --- CONFIGURATION ---
# IMPORTANT: Check this path! Change it to where your Main Menu scene is.
const MAIN_MENU_PATH = "res://UI/main_menu.tscn"

# --- UI CONTAINERS ---
@export var menu_screen: VBoxContainer
@export var open_menu_screen: VBoxContainer 

# --- PANELS ---
@export var welcome_panel: MarginContainer
@export var help_panel: MarginContainer
@export var progress_panel: MarginContainer
@export var enemies_panel: MarginContainer
@export var control_panel: MarginContainer

# --- BUTTONS (Assign in Inspector) ---
@export_group("Menu Buttons")
@export var save_button: Button 
@export var exit_button: Button # <--- ASSIGN THIS (Main Menu Exit)
@export var back_button: Button # <--- ASSIGN THIS (Inside Progress/Help panels)

# Unused/Hidden buttons
@export var help_button: Button
@export var enemies_button: Button
@export var control_button: Button

# --- VISUALS ---
@export var dimmer: ColorRect

# --- PROGRESS PANEL LABELS ---
@export var kills_label: Label
@export var level_label: Label
@export var xp_label: Label
@export var xp_bar: ProgressBar

var panels: Array[MarginContainer]

func _ready() -> void:
	panels = [
		welcome_panel,
		help_panel,
		progress_panel,
		enemies_panel,
		control_panel
	]
	
	# 1. SETUP SAVE BUTTON
	if save_button:
		if not save_button.pressed.is_connected(_on_save_button_pressed):
			save_button.pressed.connect(_on_save_button_pressed)

	# 2. SETUP NEW BUTTONS (Exit & Back)
	if exit_button:
		if not exit_button.pressed.is_connected(_on_exit_pressed):
			exit_button.pressed.connect(_on_exit_pressed)
			
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	# 3. HIDE UNUSED BUTTONS
	if help_button: help_button.visible = false
	if enemies_button: enemies_button.visible = false
	if control_button: control_button.visible = false

	# 4. INITIAL STATE
	menu_screen.visible = false
	open_menu_screen.visible = true
	dimmer.visible = false
	
	_show_panel(welcome_panel)
	_update_stats()

# --- PANEL LOGIC ---
func _show_panel(panel_to_show: MarginContainer) -> void:
	for p in panels:
		p.visible = false
	panel_to_show.visible = true

func toggle_menu() -> void:
	var opening := !menu_screen.visible

	menu_screen.visible = opening
	open_menu_screen.visible = !opening
	dimmer.visible = opening
	get_tree().paused = opening 

	if opening:
		# Always reset to Welcome panel when opening fresh
		_show_panel(welcome_panel)
		_update_stats() 

# --- BUTTON ACTIONS ---

func _on_save_button_pressed() -> void:
	print("[UI] Save Button Pressed")
	Global.save_game()
	
	if save_button:
		var original_text = save_button.text
		save_button.text = "Game Saved!"
		save_button.disabled = true 
		
		await get_tree().create_timer(1.0).timeout
		
		if is_instance_valid(save_button):
			save_button.text = original_text
			save_button.disabled = false

func _on_exit_pressed() -> void:
	print("[UI] Exiting to Main Menu...")
	# IMPORTANT: Must Unpause before changing scene!
	get_tree().paused = false 
	
	# Go to Main Menu
	TransitionScreen.transition_to(MAIN_MENU_PATH)

func _on_back_pressed() -> void:
	# Just go back to the Welcome Panel (Where Save/Exit buttons are)
	_show_panel(welcome_panel)

# --- PROGRESS UPDATES ---
func _update_stats() -> void:
	if level_label:
		level_label.text = "Current Level: " + str(Global.current_level)
	if xp_label:
		xp_label.text = "Max Level Reached: " + str(Global.max_level)
	if kills_label:
		kills_label.text = "Loop Count: " + str(Global.loop_count)
	if xp_bar:
		xp_bar.max_value = Global.GAME_LEVEL_CAP
		xp_bar.value = Global.current_level

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		toggle_menu()
		get_viewport().set_input_as_handled()

func _on_toggle_menu_button_pressed() -> void:
	toggle_menu()

func _on_progress_button_pressed() -> void:
	_update_stats()
	_show_panel(progress_panel)

# Unused
func _on_help_button_pressed() -> void: pass 
func _on_enemies_button_pressed() -> void: pass
func _on_control_button_pressed() -> void: pass
