extends Control

# OPTION 1: Drag and drop Player Component here if possible
@export var player_component_manual: PlayerUseAbilityComponent

var slots: Dictionary = {}
var active_component: PlayerUseAbilityComponent = null
func _ready() -> void:
	print("--- UI STARTUP ---")
	
	# 1. FIND PLAYER (Keep your existing code here)
	# ... (Your player finding logic is fine) ...
	if player_component_manual:
		active_component = player_component_manual
	else:
		# ... (Group finding logic) ...
		# (Paste your existing player finding code here)
		pass 

	# 2. CONNECT SIGNALS
	if active_component:
		if not active_component.magic_used.is_connected(_on_magic_used):
			active_component.magic_used.connect(_on_magic_used)
		if not active_component.mana_missing.is_connected(_on_mana_missing):
			active_component.mana_missing.connect(_on_mana_missing)
	
	# 3. SETUP SLOTS AND BUTTONS
	var container = $MarginContainer/GridContainer
	for child in container.get_children():
		if child.has_method("activate"):
			var key = child.name.replace("AbilitySlot_", "").to_lower()
			slots[key] = child
			
			# --- NEW: CONNECT BUTTON CLICK ---
			# When slot is clicked, run a specific function
			if not child.slot_clicked.is_connected(_on_slot_clicked):
				# We bind the 'key' (e.g. "fire_ball") so we know WHICH slot was clicked
				child.slot_clicked.connect(_on_slot_clicked.bind(key))
			
			if key != "fire_ball" and key != "fire_spin":
				child.lock()
# --- HANDLE SUCCESSFUL ATTACK ---


func _on_slot_clicked(key: String) -> void:
	print("🖱️ UI Clicked: ", key)
	if active_component:
		# Call the new function we added to the Player
		active_component.attempt_ability(key)
		
func _on_magic_used(attack_name: String) -> void:
	var key = attack_name.to_lower()
	if slots.has(key):
		var time = 1.0
		if active_component:
			if key == "fire_ball": time = active_component.fire_ball_cooldown
			elif key == "fire_spin": time = active_component.fire_spin_cooldown
		slots[key].activate(time)

# --- HANDLE OUT OF MANA (FIXED) ---
func _on_mana_missing(attack_name: String) -> void:
	print("❌ UI: Out of Mana for ", attack_name)
	
	var key = attack_name.to_lower()
	
	# FIND THE SLOT AND TELL IT TO FLASH BLACK
	if slots.has(key):
		slots[key].show_no_mana()
	else:
		printerr("UI Error: No slot found for ", key)
