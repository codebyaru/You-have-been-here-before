extends Control

@export var player_component_manual: PlayerUseAbilityComponent

# --- UNLOCK LEVELS ---
@export_group("Unlock Levels")
@export var level_req_fire_ball := 0
@export var level_req_fire_spin := 2
@export var level_req_water_ball := 5
@export var level_req_rock_throw := 3
@export var level_req_wind_tornado := 7
@export var level_req_shadow_summon := 9

var slots: Dictionary = {}
var active_component: PlayerUseAbilityComponent = null
var _unlocked_state: Dictionary = {}

func _ready() -> void:
	print("--- UI STARTUP DEBUG ---")
	print("Global Max Level is: ", Global.max_level)
	
	# 1. SETUP SLOTS
	var container = $MarginContainer/GridContainer
	
	for child in container.get_children():
		if child.has_method("activate"):
			var key = child.name.replace("AbilitySlot_", "").to_lower()
			slots[key] = child
			_unlocked_state[key] = false
			
			if not child.slot_clicked.is_connected(_on_slot_clicked):
				child.slot_clicked.connect(_on_slot_clicked.bind(key))
			
			child.lock()

	# 2. FIND PLAYER (Standard code...)
	if player_component_manual:
		active_component = player_component_manual
	else:
		var player_group = get_tree().get_nodes_in_group("player")
		if player_group.size() > 0:
			active_component = player_group[0].find_child("PlayerUseAbilityComponent")
			
	if active_component:
		if not active_component.magic_used.is_connected(_on_magic_used):
			active_component.magic_used.connect(_on_magic_used)
		if not active_component.mana_missing.is_connected(_on_mana_missing):
			active_component.mana_missing.connect(_on_mana_missing)
	
	# --- FIX: CHECK UNLOCKS SILENTLY ON STARTUP ---
	# Passing 'true' to skip animation
	_check_unlocks(true) 
	
	# Reset the loading flag in Global (Job done)
	if Global.is_loading_save:
		Global.is_loading_save = false

func _process(_delta: float) -> void:
	# Normal process calls it with animation enabled
	_check_unlocks(false)

# Added 'skip_anim' parameter
func _check_unlocks(skip_anim: bool) -> void:
	var lvl = Global.max_level
	
	check_ability_unlock("fire_ball", level_req_fire_ball, lvl, skip_anim)
	check_ability_unlock("fire_spin", level_req_fire_spin, lvl, skip_anim)
	check_ability_unlock("water_ball", level_req_water_ball, lvl, skip_anim)
	check_ability_unlock("rock_throw", level_req_rock_throw, lvl, skip_anim)
	check_ability_unlock("wind_tornado", level_req_wind_tornado, lvl, skip_anim)
	check_ability_unlock("shadow_summon",level_req_shadow_summon, lvl, skip_anim)

func check_ability_unlock(key: String, required_level: int, current_lvl: int, skip_anim: bool) -> void:
	if not slots.has(key): 
		return

	if current_lvl >= required_level:
		if _unlocked_state[key] == false:
			_unlocked_state[key] = true # Mark as unlocked
			
			if skip_anim:
				# If we are loading, just unlock instantly without fanfare
				# Assuming your slot has an .unlock() method, we call it.
				# If your slot's .unlock() forces animation, you might need to add a method 
				# to the SLOT script like .instant_unlock() or just .visible = true
				slots[key].unlock() 
				print("✨ Silent Unlock (Load): ", key)
			else:
				# Normal gameplay unlock (plays animation)
				print("✨ NEW Unlock (Level Up): ", key)
				slots[key].unlock()
				
	else:
		if _unlocked_state[key] == true:
			slots[key].lock()
			_unlocked_state[key] = false


# --- CLICKS & COOLDOWNS ---
func _on_slot_clicked(key: String) -> void:
	if _unlocked_state.has(key) and _unlocked_state[key] == false:
		return # Locked, ignore click
	if active_component:
		active_component.attempt_ability(key)

func _on_magic_used(attack_name: String) -> void:
	var key = attack_name.to_lower()
	if slots.has(key):
		var time = 1.0
		if active_component:
			match key:
				"fire_ball": time = active_component.fire_ball_cooldown
				"fire_spin": time = active_component.fire_spin_cooldown
				"water_ball": time = active_component.water_ball_cooldown
				"rock_throw": time = active_component.rock_throw_cooldown
				"wind_tornado": time = active_component.wind_tornado_cooldown
				"shadow_summon": time  = active_component.shadow_summon_cooldown
		slots[key].activate(time)

func _on_mana_missing(attack_name: String) -> void:
	var key = attack_name.to_lower()
	if slots.has(key):
		slots[key].show_no_mana()
