class_name Projectile
extends Node2D

@export var speed = 400.0
var direction = Vector2.ZERO
var source : Node
var launched = false

# 🔥 Sprite reference (AnimatedSprite2D ya Sprite2D)
@onready var sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	call_deferred("_validate_setup")

func _physics_process(delta: float) -> void:
	if not launched:
		return
	
	position += direction * speed * delta

func launch(p_source: Node, p_direction: Vector2):
	launched = true
	source = p_source
	
	# --- SMART AIMING FOR MAHORAGA ---
	if source and source.has_method("mahoraga"):
		var target_node = null
		
		if "player" in source and is_instance_valid(source.player):
			target_node = source.player
		elif Global.player_ref and is_instance_valid(Global.player_ref):
			target_node = Global.player_ref
		
		if target_node:
			# Calculate direction towards player
			var target_pos = target_node.global_position + Vector2(0, -18)
			var my_pos = global_position
			direction = (target_pos - my_pos).normalized()
			
			print("[PROJECTILE] 🎯 Mahoraga Locked on! Direction: ", direction)
		else:
			direction = p_direction
	else:
		# Normal launch
		direction = p_direction
	
	# 🔥 CRITICAL FIX: Direction set hone ke BAAD PURA node flip karo
	_update_flip()

func _update_flip():
	"""Pura Node2D flip karo (sprite + collision boxes sab aligned rahenge)"""
	# Agar LEFT jaa raha (negative x), toh pura node flip karo
	if direction.x < 0:
		scale.x = -abs(scale.x)  # Negative scale (flip left)
	elif direction.x > 0:
		scale.x = abs(scale.x)   # Positive scale (flip right)
	# Agar exactly vertical (x = 0), toh current flip state rakho

func _validate_setup():
	if not launched:
		push_warning("⚠️ Projectile created but launch() was not called!")

func projectile():
	pass
