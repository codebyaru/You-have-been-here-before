class_name ProjectileLaunchAbility
extends Ability

@export var projectile_scene: PackedScene
@export var instancing_offset : Vector2

func use(p_user: Node2D) -> bool:
	# 1. Sabse pehle Current Input check karo (Instant reaction ke liye)
	# "ui_left" aur "ui_right" ko apne Input Map ke hisab se change kar lena agar alag ho
	var input_dir = Input.get_axis("ui_left", "ui_right")
	
	var facing_direction = 1.0 # Default Right
	
	if input_dir != 0:
		# Agar player button daba raha hai, toh wahi direction hai
		facing_direction = input_dir
	else:
		# Agar player rukka hua hai (Idle), toh Sprite se pucho wo kahan dekh raha hai
		# Hum assume kar rahe hain node ka naam "AnimatedSprite2D" ya "Sprite2D" hai
		var sprite = p_user.get_node_or_null("AnimatedSprite2D")
		
		if sprite == null:
			sprite = p_user.get_node_or_null("Sprite2D")
			
		if sprite:
			# Agar Sprite flipped hai (True), matlab Left (-1) dekh raha hai
			if sprite.flip_h == true:
				facing_direction = -1.0
			else:
				facing_direction = 1.0
	
	# --- Baaki code same rahega ---
	
	var instance : Projectile = projectile_scene.instantiate()
	p_user.get_parent().add_child(instance)
	
	# Offset ko direction ke hisab se flip karna
	var final_offset = Vector2(instancing_offset.x * facing_direction, instancing_offset.y)
	instance.global_position = p_user.global_position + final_offset
	
	instance.launch(p_user, Vector2(facing_direction, 0))
	
	return true
