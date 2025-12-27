extends Control

@export var player_component_manual: PlayerUseAbilityComponent

# --- UNLOCK LEVELS ---
@export_group("Unlock Levels")
@export var level_req_fire_ball := 0
@export var level_req_fire_spin := 2
@export var level_req_water_ball := 3
@export var level_req_rock_throw := 5
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
			# --- CRITICAL: NAME CLEANING ---
			# Converts "AbilitySlot_Fire_Ball" -> "fire_ball"
			# Converts "AbilitySlot_FireBall" -> "fireball" (Use underscores in Scene Tree!)
			var key = child.name.replace("AbilitySlot_", "").to_lower()
			
			print("Found Slot Node: ", child.name, " | Registered Key: ", key)
			
			slots[key] = child
			_unlocked_state[key] = false
			
			# Connect Click
			if not child.slot_clicked.is_connected(_on_slot_clicked):
				child.slot_clicked.connect(_on_slot_clicked.bind(key))
			
			# Lock everyone first
			child.lock()

	# 2. FIND PLAYER
	if player_component_manual:
		active_component = player_component_manual
	else:
		var player_group = get_tree().get_nodes_in_group("player")
		if player_group.size() > 0:
			active_component = player_group[0].find_child("PlayerUseAbilityComponent")
			
	# 3. CONNECT PLAYER SIGNALS
	if active_component:
		if not active_component.magic_used.is_connected(_on_magic_used):
			active_component.magic_used.connect(_on_magic_used)
		if not active_component.mana_missing.is_connected(_on_mana_missing):
			active_component.mana_missing.connect(_on_mana_missing)
	
	# 4. CHECK UNLOCKS IMMEDIATELY (Don't wait for _process)
	_check_unlocks()

func _process(_delta: float) -> void:
	_check_unlocks()

func _check_unlocks() -> void:
	# Ensure Global Level is readable
	var lvl = Global.max_level
	
	# Check all spells against the generated keys
	check_ability_unlock("fire_ball", level_req_fire_ball, lvl)
	check_ability_unlock("fire_spin", level_req_fire_spin, lvl)
	check_ability_unlock("water_ball", level_req_water_ball, lvl)
	check_ability_unlock("rock_throw", level_req_rock_throw, lvl)
	check_ability_unlock("wind_tornado", level_req_wind_tornado, lvl)
	check_ability_unlock("shadow_summon",level_req_shadow_summon,lvl)

func check_ability_unlock(key: String, required_level: int, current_lvl: int) -> void:
	# If this key doesn't exist in slots, we printed it in _ready, so check output!
	if not slots.has(key): 
		return

	if current_lvl >= required_level:
		if _unlocked_state[key] == false:
			print("✨ Unlocking: ", key)
			slots[key].unlock()
			_unlocked_state[key] = true
	else:
		# If level is too low, keep locked
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
