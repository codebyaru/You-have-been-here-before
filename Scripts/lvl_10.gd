extends Node2D

# Flag taaki dialogue sirf ek baar trigger ho
var critical_dialogue_triggered := false

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
			Global.loop_count+=1
			Global.dialogue_playing = false # Release control strictly if needed, but switching scene anyway
			Global.proceed_to_next_level()
			
		"said_no":
			print(" -> Triggering Ending Timeline")
			# Dialogue playing remains true
			Dialogic.start("ending")
			
		"timeline_end": # Agar tumhare dialogue ke end mein ye signal hai cleanup ke liye
			Global.dialogue_playing = false

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
