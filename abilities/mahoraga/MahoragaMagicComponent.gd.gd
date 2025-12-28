class_name MahoragaMagicComponent
extends Node

# --- SAME RESOURCES AS PLAYER ---
# Editor mein wahi Ability Resources drag-drop karna jo Player ke paas hain
@export var ability_fire_spin : Ability
@export var ability_fire_ball : Ability
@export var ability_water_ball : Ability
@export var ability_rock_throw: Ability
@export var ability_wind_tornado: Ability
@export var ability_shadow_summon: Ability

@export var user : CharacterBody2D # Assign Mahoraga here

# --- AI COOLDOWNS ---
# Boss should not spam like a machine gun
var cooldowns : Dictionary = {} 
var global_magic_cooldown : bool = false

func _process(delta: float) -> void:
	# Cooldown timers reduce karo
	for key in cooldowns.keys():
		if cooldowns[key] > 0:
			cooldowns[key] -= delta

# --- MAIN FUNCTION ---
func try_cast_stolen_magic(element_name: String):
	# 1. Global Cooldown Check (Taaki ek saath 5 attacks na kare)
	if global_magic_cooldown: return
	
	# 2. Specific Ability Cooldown Check
	if cooldowns.has(element_name) and cooldowns[element_name] > 0:
		return

	# 3. Match Element to Ability Resource
	var ability_to_use : Ability = null
	var cooldown_time : float = 2.0 # Default cooldown for boss
	
	match element_name:
		"fire":
			# Boss can decide between ball or spin randomly
			ability_to_use = ability_fire_ball
			
			cooldown_time = 1.5
		"water":
			ability_to_use = ability_water_ball
			cooldown_time = 1.5
		"rock":
			ability_to_use = ability_rock_throw
			cooldown_time = 2.0
		"wind":
			ability_to_use = ability_wind_tornado
			cooldown_time = 2.5
		"shadow":
			ability_to_use = ability_shadow_summon
			cooldown_time = 5.0 # Summon is strong, longer CD
		"fire_spin":
			ability_to_use = ability_fire_spin

	# 4. EXECUTE CAST
	if ability_to_use:
		print("MAHORAGA USING STOLEN MAGIC: ", element_name)
		ability_to_use.use(user) # Uses the same logic as Player!
		
		# Set Cooldowns
		cooldowns[element_name] = cooldown_time
		_trigger_global_cooldown()

func _trigger_global_cooldown():
	global_magic_cooldown = true
	# 1 second wait before he can cast ANY magic again
	await get_tree().create_timer(1.0).timeout 
	global_magic_cooldown = false
