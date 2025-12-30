class_name Projectile
extends Node2D

@export var speed = 400.0
var direction = Vector2.ZERO
var source : Node
var launched = false

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
			# NO AWAIT NEEDED - Position already set hai
			var target_pos = target_node.global_position + Vector2(0, -30)    
			var my_pos = global_position
			direction = (target_pos - my_pos).normalized()
			
			print("[PROJECTILE] Locked on! Direction: ", direction)
		else:
			direction = p_direction
	else:
		direction = p_direction
	
	

func _validate_setup():
	if not launched:
		push_warning("Projectile created but launch() was not called!")

func projectile():
	pass
