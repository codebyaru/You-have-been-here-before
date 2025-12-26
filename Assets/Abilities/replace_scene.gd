class_name ReplaceScene
extends Node

@export var replace_target : Node
@export_file var replacement_scene_path : String 

# --- NEW EXPORT VARIABLES ---
# Ye variables Inspector mein dikhenge. 
# Fireball ke liye 200/1.0 set karo, Spin ke liye 500/3.0 set karo.
@export var replace_damage : int = 1
@export var replace_scale : float =1
# ----------------------------
func replace():
	if replacement_scene_path == "" or replacement_scene_path == null:
		printerr("ERROR: Path empty")
		return

	var scene_resource = load(replacement_scene_path)
	if scene_resource == null:
		return

	var instance : Node2D = scene_resource.instantiate()
	
	# --- YE CODE CHANGE KARO ---
	
	# 1. Pehle check karo: Kya Root (FireExplosion) par setup hai?
	if instance.has_method("setup"):
		print("callled setup")
		instance.setup(replace_damage, replace_scale)
		
	# 2. Agar Root par nahi hai, toh Children mein dhoondo
	else:
		# Sare children check karo (GrowOverTime, AnimatedSprite, etc.)
		for child in instance.get_children():
			if child.has_method("setup"):
				# Mil gaya! Ab data pass karo
				child.setup(replace_damage, replace_scale)
				
				print("Sendng damge and scale",replace_damage,replace_scale)
				break # Ek bar mil gaya toh loop rok do
				
	# ---------------------------
	
	call_deferred("_reposition_and_free", instance)
func _reposition_and_free(p_instance : Node2D):
	if replace_target == null:
		# Safety check agar target pehle hi delete ho gaya ho
		p_instance.queue_free()
		return
		
	replace_target.get_parent().add_child(p_instance)
	p_instance.global_position = replace_target.global_position
	replace_target.queue_free()
