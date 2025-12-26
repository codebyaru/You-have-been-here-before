class_name PlayerUseAbilityComponent
extends Node

@export var use_ability_action_name_fire_spin = "ability_fire_spin"
@export var use_ability_action_name_fire_ball = "ability_fire_ball"
@export var ability_fire_spin : Ability
@export var ability_fire_ball : Ability
@export var user : Node2D

@export var fire_spin_cooldown := 0.8
@export var fire_ball_cooldown := 0.6

# --- NEW SIGNAL ADDED HERE ---
signal magic_used(attack_name: String)
signal mana_missing(attack_name: String) 

var _can_fire_spin := true
var _can_fire_ball := true

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(use_ability_action_name_fire_spin):
		_try_fire_spin()

	if event.is_action_pressed(use_ability_action_name_fire_ball):
		_try_fire_ball()

func _try_fire_spin() -> void:
	if not _can_fire_spin: return
	if ability_fire_spin == null: return
	
	# --- MANA CHECK ---
	if not _has_mana(12):
		print("[MAGIC] ❌ Not enough mana for FIRE SPIN")
		emit_signal("mana_missing", "fire_spin") # <--- TELL UI
		return

	print("FIRE SPIN ATTACK")
	_can_fire_spin = false
	ability_fire_spin.use(user)
	emit_signal("magic_used", "fire_spin")

	await get_tree().create_timer(fire_spin_cooldown).timeout
	_can_fire_spin = true

func _try_fire_ball() -> void:
	if not _can_fire_ball: return
	if ability_fire_ball == null: return
	
	# --- MANA CHECK ---
	if not _has_mana(5):
		print("[MAGIC] ❌ No mana for fire_ball")
		emit_signal("mana_missing", "fire_ball") # <--- TELL UI
		return

	_can_fire_ball = false
	ability_fire_ball.use(user)
	emit_signal("magic_used", "fire_ball")

	await get_tree().create_timer(fire_ball_cooldown).timeout
	_can_fire_ball = true

func _has_mana(cost: int) -> bool:
	if user == null: return false
	if not user.has_method("get_current_mana"): return true
	return user.get_current_mana() >= cost


# --- NEW FUNCTION FOR UI CLICKS ---
func attempt_ability(ability_name: String) -> void:
	match ability_name:
		"fire_ball":
			_try_fire_ball()
		"fire_spin":
			_try_fire_spin()
		_:
			print("Player doesn't know how to use: ", ability_name)
