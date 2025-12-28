extends Node2D

# --- CONFIGURATION ---
@export_group("Platforms")
@export var platform_1: TileMap 
@export var platform_2: TileMap
@export var platform_3: TileMap

@export_group("Targets")
@export var target_1: Area2D
@export var target_2: Area2D
@export var target_3: Area2D

# --- STATE VARIABLES (For Movement) ---
var time_passed: float = 0.0
var target_data = {} # Yahan hum targets ki starting position save karenge

func _ready() -> void:
	Global.current_level_id = "lvl6"
	Global.current_level = 6
	Global.respawn_position = Vector2(14, 258)
	
	if WaveHandler.has_signal("all_waves_completed"):
		WaveHandler.all_waves_completed.connect(_on_waves_done)

	# --- LEVEL SETUP ---
	_setup_level()

func _process(delta: float) -> void:
	# --- SINE WAVE MOVEMENT LOGIC ---
	time_passed += delta
	
	# Sirf active targets ko move karo
	if _is_target_active(target_1):
		target_1.position.y = target_data[target_1]["start_y"] + sin(time_passed * 2.0) * 30
		
	if _is_target_active(target_2):
		target_2.position.y = target_data[target_2]["start_y"] + sin(time_passed * 3.5) * 60
		
	if _is_target_active(target_3):
		target_3.position.y = target_data[target_3]["start_y"] + sin(time_passed * 1.5) * 100

# ---------------------------------------------------------
# --- SETUP & HIT LOGIC ---
# ---------------------------------------------------------

func _setup_level():
	# 1. Hide Platforms (Layer 0 Disable)
	_toggle_platform(platform_1, false)
	_toggle_platform(platform_2, false)
	_toggle_platform(platform_3, false)
	
	# 2. Store Start Positions (Movement ke liye zaroori hai)
	target_data.clear()
	if target_1: target_data[target_1] = {"start_y": target_1.position.y, "hit": false, "linked_plat": platform_1}
	if target_2: target_data[target_2] = {"start_y": target_2.position.y, "hit": false, "linked_plat": platform_2}
	if target_3: target_data[target_3] = {"start_y": target_3.position.y, "hit": false, "linked_plat": platform_3}

# YE FUNCTION TERA TARGET.GD CALL KAREGA (Signal ki zarurat nahi)
func target_hit_logic(hit_target_node):
	if target_data.has(hit_target_node):
		var data = target_data[hit_target_node]
		
		# Agar pehle se hit nahi hua hai
		if data["hit"] == false:
			print("[LEVEL 6] Target Hit Success!")
			
			# 1. Mark as Hit (Movement stops)
			data["hit"] = true
			
			# 2. Visual Feedback (Grey Color)
			var visual = hit_target_node.get_node_or_null("ColorRect")
			if visual:
				visual.color = Color(0.2, 0.2, 0.2, 0.5)
			
			# 3. Unlock Platform
			_toggle_platform(data["linked_plat"], true)

# Helper: Check if target should move
func _is_target_active(t):
	return t and target_data.has(t) and target_data[t]["hit"] == false

# Helper: Platform Toggle
func _toggle_platform(plat: TileMap, enable: bool):
	if plat:
		plat.visible = enable
		plat.set_layer_enabled(0, enable)
		
		if enable:
			# Ghost Fade Effect
			plat.modulate.a = 0.0
			var tween = create_tween()
			tween.tween_property(plat, "modulate:a", 1.0, 1.5)

# ---------------------------------------------------------
# --- EXISTING LOGIC ---
# ---------------------------------------------------------
func _on_void_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		body.take_damage(body.max_health)
	if body.has_method("enemy"):
		body.take_damage(body.MAX_HEALTH)
	if body.has_method("shadow"):
		body.take_damage(body.MAX_HEALTH)

func _on_waves_done(level_id):
	pass
