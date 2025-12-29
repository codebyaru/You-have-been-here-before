extends State
class_name SettingsMenuState

# Drag your Settings UI Control node here
@export var settings_ui_container : Control 

# Drag your Juicy Player here (to play the "Back" animation)
@export var return_to_main_juicy : Juicy_player 

# Drag the Main Menu State node here
@export var main_menu_state : State 

# 1. When we enter this state, SHOW the settings
func Enter():
	settings_ui_container.visible = true
	# You might want to focus a button here
	# $VBoxContainer/VolumeSlider.grab_focus()

# 2. When we leave this state, HIDE the settings
func Exit():
	settings_ui_container.visible = false

# 3. Check for the "Back" button every frame
func Update(_delta: float):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()

# 4. Logic to go back
func _on_back_pressed():
	return_to_main_juicy.Play() # Play animation
	Transitioned.emit(self, main_menu_state) # Switch Logic

# 5. THIS IS THE MISSING LINK FOR YOUR BUTTON!
# Connect your Settings Button "Pressed" signal to this function
func _direct_enter_state():
	# This tells the StateMachine: "Switch from whatever you are doing -> TO ME"
	Transitioned.emit(state_machine.current_state, self)
