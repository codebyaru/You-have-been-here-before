class_name SummonAbility
extends Ability

@export var summon_scene: PackedScene
@export var spawn_offset : Vector2 = Vector2(30, 0) # Thoda door spawn karein

func use(p_user: Node2D) -> bool:
	print("\n[SUMMON_DEBUG] --- Starting Summon Sequence ---")
	
	# 1. SCENE CHECK
	if summon_scene == null:
		printerr("[SUMMON_DEBUG] ❌ ERROR: 'Summon Scene' is Empty in Inspector!")
		return false
	else:
		print("[SUMMON_DEBUG] ✅ Summon Scene Found.")

	if p_user == null:
		printerr("[SUMMON_DEBUG] ❌ ERROR: 'p_user' is null!")
		return false

	# 2. DIRECTION LOGIC
	var input_dir = Input.get_axis("ui_left", "ui_right")
	var facing_direction = 1.0 # Default Right
	
	if input_dir != 0:
		facing_direction = input_dir
	else:
		var sprite = p_user.get_node_or_null("AnimatedSprite2D")
		if sprite == null:
			sprite = p_user.get_node_or_null("Sprite2D")
			
		if sprite:
			if sprite.flip_h == true:
				facing_direction = -1.0
			else:
				facing_direction = 1.0
	
	print("[SUMMON_DEBUG] Facing Direction calculated: ", facing_direction)

	# 3. INSTANTIATION
	var instance = summon_scene.instantiate()
	if instance == null:
		printerr("[SUMMON_DEBUG] ❌ ERROR: Failed to instantiate scene!")
		return false
	
	# 4. PARENTING CHECK
	var parent_node = p_user.get_parent()
	if parent_node == null:
		printerr("[SUMMON_DEBUG] ❌ ERROR: Player has no Parent! Cannot add child to world.")
		# Fallback: Agar parent nahi mila to khud player me add kar do (not recommended but avoids crash)
		p_user.add_child(instance)
	else:
		parent_node.add_child(instance)
		print("[SUMMON_DEBUG] ✅ Monster added to World (Parent: ", parent_node.name, ")")
	
	# 5. POSITIONING
	var final_offset = Vector2(spawn_offset.x * facing_direction, spawn_offset.y)
	instance.global_position = p_user.global_position + final_offset
	print("[SUMMON_DEBUG] Spawn Position: ", instance.global_position)
	
	# 6. SETUP CALL
	if instance.has_method("setup_summon"):
		print("[SUMMON_DEBUG] Calling 'setup_summon' on monster.")
		instance.setup_summon(facing_direction)
	elif instance.has_method("set_direction"):
		print("[SUMMON_DEBUG] Calling 'set_direction' on monster.")
		instance.set_direction(facing_direction)
	else:
		print("[SUMMON_DEBUG] ⚠️ Warning: Monster script has no 'setup_summon' or 'set_direction' function.")
		
	print("[SUMMON_DEBUG] --- Summon Complete ---\n")
	return true
