class_name ReplaceScene
extends Node

@export var replace_target : Node
@export_file var replacement_scene_path : String 

@export var spawn_replacement : bool = true 

# --- DAMAGE/SCALE VARIABLES ---
@export var replace_damage : int = 1
@export var replace_scale : float = 1

func replace():
	# --- LOGIC CHECK 1: DO WE WANT AN EXPLOSION? ---
	# Agar Fire Spin hai (spawn_replacement = false), to bas purana delete karo aur return karo.
	if not spawn_replacement:
		if replace_target:
			replace_target.queue_free()
		return

	# --- LOGIC CHECK 2: PATH EXISTS? ---
	if replacement_scene_path == "" or replacement_scene_path == null:
		printerr("ERROR: Path empty")
		return

	var scene_resource = load(replacement_scene_path)
	if scene_resource == null:
		return

	var instance : Node2D = scene_resource.instantiate()
	
	# --- SETUP DATA PASSING ---
	if instance.has_method("setup"):
		# print("called setup on root")
		instance.setup(replace_damage, replace_scale)
	else:
		for child in instance.get_children():
			if child.has_method("setup"):
				child.setup(replace_damage, replace_scale)
				# print("Sending damage and scale to child", replace_damage, replace_scale)
				break 
				
	call_deferred("_reposition_and_free", instance)

func _reposition_and_free(p_instance : Node2D):
	if replace_target == null:
		p_instance.queue_free()
		return
		
	replace_target.get_parent().add_child(p_instance)
	p_instance.global_position = replace_target.global_position
	replace_target.queue_free()
