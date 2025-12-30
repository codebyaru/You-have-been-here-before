class_name ProjectileLaunchAbility
extends Ability

@export var projectile_scene: PackedScene
@export var instancing_offset : Vector2

func use(p_user: Node2D) -> bool:
	var facing_direction = 1.0 # Default Right
	
	# --- MAHORAGA KE LIYE SPECIAL LOGIC ---
	if p_user.has_method("mahoraga"):
		# Mahoraga hai! Seedha player ki taraf direction calculate karo
		var target_node = null
		
		# Try to get player reference
		if "player" in p_user and is_instance_valid(p_user.player):
			target_node = p_user.player
		elif Global.player_ref and is_instance_valid(Global.player_ref):
			target_node = Global.player_ref
		
		if target_node:
			# Player ka position - Mahoraga ka position = Direction
			var direction_to_player = (target_node.global_position - p_user.global_position).normalized()
			
			# Facing direction set karo based on X-axis
			facing_direction = sign(direction_to_player.x)
			
			# Agar exactly upar/neeche hai (x = 0), default right rakh do
			if facing_direction == 0:
				facing_direction = 1.0
			
			print("[ABILITY] Mahoraga aiming at player! Direction: ", direction_to_player)
	else:
		# --- NORMAL ENTITIES (PLAYER) KE LIYE PURANA LOGIC ---
		var input_dir = Input.get_axis("ui_left", "ui_right")
		
		if input_dir != 0:
			facing_direction = input_dir
		else:
			# Idle state - Sprite se direction nikalo
			var sprite = p_user.get_node_or_null("AnimatedSprite2D")
			
			if sprite == null:
				sprite = p_user.get_node_or_null("Sprite2D")
				
			if sprite:
				facing_direction = -1.0 if sprite.flip_h else 1.0
	
	# --- PROJECTILE INSTANTIATE ---
	var instance : Projectile = projectile_scene.instantiate()
	p_user.get_parent().add_child(instance)
	
	# Offset ko facing direction ke hisab se adjust karo
	var final_offset = Vector2(instancing_offset.x * facing_direction, instancing_offset.y)
	instance.global_position = p_user.global_position + final_offset
	
	# Launch with horizontal direction (Projectile.gd mein smart aiming hogi)
	instance.launch(p_user, Vector2(facing_direction, 0))
	
	return true
