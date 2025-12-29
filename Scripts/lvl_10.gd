extends Node2D

# Flag taaki dialogue sirf ek baar trigger ho
var critical_dialogue_triggered := false
@export_file("*.tscn") var next_scene_path: String
func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sharperheart - Bittersweet.mp3")
	Global.current_level_id = "lvl10"
	Global.current_level = 10
	
	WaveHandler.all_waves_completed.connect(_on_waves_done)
	
	# Dialogic Signals Connect karna zaroori hai
	Dialogic.signal_event.connect(_on_dialogic_signal)
	
	Global.respawn_position = Vector2(14, 258)
	#DialogicController.start_dialogue("timeline_4")
	#$Beacon.start_timer()

# --- 🔥 CRITICAL HEALTH MONITORING ---
func _process(_delta) -> void:
	# 1. Check agar dialogue pehle se trigger nahi hua hai
	# 2. Check agar Player exist karta hai
	if not critical_dialogue_triggered and is_instance_valid(Global.player_ref):
		
		# 3. Check variable from player.gd
		if Global.player_ref.is_critical_health:
			_trigger_critical_sequence()

# Lvl10.gd

func _trigger_critical_sequence():
	# ... (baaki logic) ...
	print("[LVL10] Manually Freezing Entities...")
	
	# 1. Player ko Roko
	if is_instance_valid(Global.player_ref):
		Global.player_ref.set_physics_process(false) # Physics Band
		Global.player_ref.set_process(false)         # Input Band
		Global.player_ref.sprite.pause()             # Animation Band (Optional)
		
	# 2. Mahoraga/Enemies ko Roko
	# Iske liye best hai ki saare enemies "enemies" group mein hon
	get_tree().call_group("enemies", "set_physics_process", false)
	get_tree().call_group("enemies", "set_process", false)
	
	# Agar Mahoraga alag hai aur group mein nahi hai:
	var mahoraga = get_node_or_null("Mahoraga") # Path check karlena
	if mahoraga:
		mahoraga.set_physics_process(false)
		mahoraga.sprite.pause()
	print("[LVL10] ⚠️ Player Critical! Starting Final Choice...")
	critical_dialogue_triggered = true
	
	# Player movement rokne ke liye
	Global.dialogue_playing = true 
	
	# Start the dialogue
	Dialogic.start("lvl10")

# --- 🔥 SIGNAL HANDLER (YES / NO) ---
func _on_dialogic_signal(arg: String):
	print("[LVL10] Signal received: ", arg)
	
	match arg:
		"said_yes":
			print(" -> Advancing Level (Beacon Style)")
			Global.loop_count += 1
			Global.dialogue_playing = false 
			Global.proceed_to_next_level()
			
		"said_no":
			print(" -> Triggering Ending Timeline")
			
			# 1. Ending Dialogue Start karo
			Dialogic.start("ending")
			
			# 🔥 CHECK: Abhi scene change mat karo!
			# Signal connect karo jo wait karega dialogue khatam hone ka
			if not Dialogic.timeline_ended.is_connected(_on_ending_finished):
				Dialogic.timeline_ended.connect(_on_ending_finished)

		"timeline_end": 
			# Ye normal dialogues ke liye hai
			Global.dialogue_playing = false

# --- 🔥 NAYA FUNCTION ADD KARO ---
# Ye tab chalega jab "ending" dialogue poora khatam ho jayega
func _on_ending_finished():
	print("Ending Dialogue Complete. Transitioning Scene...")
	
	# 1. Cleanup: Signal disconnect karna zaroori hai
	if Dialogic.timeline_ended.is_connected(_on_ending_finished):
		Dialogic.timeline_ended.disconnect(_on_ending_finished)
	
	Global.dialogue_playing = false
	
	# 2. Ab Scene Change karo
	if next_scene_path:
		AudioManager.stop_music()
		TransitionScreen.transition_to(next_scene_path)
	else:
		print("❌ Error: Next Scene Path set nahi hai!")
# --- VOID LOGIC (Existing) ---
func _on_void_body_entered(body: Node2D) -> void:
	if body.has_method("player"):
		print("Instant death")
		# "void" pass kiya taaki critical health trigger na ho
		body.take_damage(body.max_health, "void") 
	if body.has_method("enemy"):
		body.take_damage(body.MAX_HEALTH)
	if body.has_method("shadow"):
		body.take_damage(body.MAX_HEALTH)

func _on_waves_done(level_id):
	if level_id == "lvl2":
		print("[LEVEL 2] Combat complete")
