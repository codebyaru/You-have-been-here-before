extends Node2D

# Inspector mein Main Menu scene ka path set karna
@export_file("*.tscn") var next_scene_path: String

# 🔥 Yahan apna Label drag-drop karna Inspector mein
@export var credits_label: Control 

# Kitna upar bhejna hai (pixels)
@export var move_distance: float = 150.0 
@export var duration: float = 3.0

func _ready():
	if credits_label == null:
		print("❌ Error: Inspector mein 'Credits Label' assign nahi kiya!")
		return

	# 1. Tween start karo
	var tween = create_tween()
	
	# 2. Sirf LABEL ko upar move karo
	# Initial position se 'move_distance' minus karke upar le jayenge
	var target_y = credits_label.position.y - move_distance
	
	tween.tween_property(credits_label, "position:y", target_y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# 3. Animation khatam hone par scene change
	tween.finished.connect(_on_credits_finished)

func _on_credits_finished():
	print("Credits finished. Changing scene...")
	if next_scene_path:
		TransitionScreen.transition_to(next_scene_path)

# Skip karne ka option (Optional)
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		_on_credits_finished()
