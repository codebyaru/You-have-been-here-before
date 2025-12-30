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
@export var ability_void_attack: Ability
@export var user : CharacterBody2D # Assign Mahoraga here

# --- AI COOLDOWNS ---
var cooldowns : Dictionary = {} 
var global_magic_cooldown : bool = false

func _process(delta: float) -> void:
	for key in cooldowns.keys():
		if cooldowns[key] > 0:
			cooldowns[key] -= delta

# --- MAIN FUNCTION ---
func try_cast_stolen_magic(element_name: String):
	if global_magic_cooldown: return
	
	if cooldowns.has(element_name) and cooldowns[element_name] > 0:
		return

	var ability_to_use : Ability = null
	var cooldown_time : float = 2.0 
	
	match element_name:
		"void": # 🔥 NEW: Default Attack Logic
			ability_to_use = ability_void_attack
			cooldown_time = 3.0 # Thoda strong hai, so 3 sec cooldown
		"fire":
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
			cooldown_time = 5.0
		"fire_spin":
			ability_to_use = ability_fire_spin

	if ability_to_use:
		print("MAHORAGA CASTING: ", element_name.to_upper())
		ability_to_use.use(user)
		
		cooldowns[element_name] = cooldown_time
		_trigger_global_cooldown()

func _trigger_global_cooldown():
	global_magic_cooldown = true
	# 1.5 sec wait taaki spam na kare (Smart casting)
	await get_tree().create_timer(1.5).timeout 
	global_magic_cooldown = false
