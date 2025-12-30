extends Node2D

# --- 1. INSPECTOR VARIABLES ---
@export var mahoraga_scene: PackedScene 
@export var boss_spawn_pos: Marker2D 
@export_file("*.tscn") var next_scene_path: String 

# Internal flag
var critical_dialogue_triggered := false

func _ready() -> void:
	# 1. Level Setup
	Global.current_level_id = "lvl10"
	Global.current_level = 10
	Global.respawn_position = Vector2(14, 258)
	
	# 2. 🔥 PAUSE & HIDE PLAYER (Cinematic Start)
	if is_instance_valid(Global.player_ref):
		Global.player_ref.visible = false            # Gayab karo
		Global.player_ref.set_physics_process(false) # Hilna band
		Global.player_ref.set_process(false)         # Input/Logic band
		Global.player_ref.velocity = Vector2.ZERO    # Slide rok do
	
	# 3. Start Intro Dialogue
	Dialogic.start("lvl10_start")
	
	# 4. Signals Connect
	Dialogic.signal_event.connect(_on_dialogic_signal)

# --- 2. CRITICAL HEALTH MONITORING ---
func _process(_delta) -> void:
	if not critical_dialogue_triggered and is_instance_valid(Global.player_ref):
		if Global.player_ref.is_critical_health:
			_trigger_critical_sequence()

# --- 3. SIGNAL HANDLER (MAIN LOGIC) ---
func _on_dialogic_signal(arg: String):
	print("[LVL10] Signal received: ", arg)
	
	match arg:
		"final_fight":
			print("🔥 Intro Finished. Summoning Mahoraga!")
			
			# 🔥 UNPAUSE PLAYER (Fight Mode ON)
			if is_instance_valid(Global.player_ref):
				Global.player_ref.visible = true
				Global.player_ref.set_physics_process(true) # Hilna chalu
				Global.player_ref.set_process(true)         # Input chalu
				
			_summon_mahoraga()
			Global.dialogue_playing = false
			
		"said_yes":
			print(" -> Choice: YES (Loop)")
			Global.loop_count += 1
			Global.dialogue_playing = false 
			Global.proceed_to_next_level()
			
		"said_no":
			print(" -> Choice: NO (Ending)")
			# Player is already hidden/paused from critical sequence logic
			Dialogic.start("ending")
			
			if not Dialogic.timeline_ended.is_connected(_on_ending_finished):
				Dialogic.timeline_ended.connect(_on_ending_finished)

		"timeline_end":
			# Safe Check: Agar koi normal dialogue khatam ho to player dikha do
			# Note: Isse careful rehna, agar 'final_fight' signal use kar rahe ho to ye zaroori nahi hai
			if is_instance_valid(Global.player_ref) and arg != "start_fight":
				Global.player_ref.visible = true
				Global.player_ref.set_physics_process(true)
				Global.player_ref.set_process(true)
			Global.dialogue_playing = false

# --- 4. SUMMON BOSS ---
func _summon_mahoraga():
	AudioManager.play_music("res://audio/music/Sharperheart - Bittersweet.mp3")
	if mahoraga_scene and boss_spawn_pos:
		var boss = mahoraga_scene.instantiate()
		boss.global_position = boss_spawn_pos.global_position
		boss.add_to_group("enemies") 
		add_child(boss)
		print("✅ Mahoraga Summoned")
	else:
		push_error("[LVL10] ❌ Error: Mahoraga Scene/SpawnPos Missing!")

# --- 5. FREEZE GAME (CRITICAL SEQUENCE) ---
func _trigger_critical_sequence():
	print("[LVL10] ⚠️ Triggering Critical Choice...")
	critical_dialogue_triggered = true
	Global.dialogue_playing = true 
	
	# Player Handling (Freeze Again)
	if is_instance_valid(Global.player_ref):
		Global.player_ref.set_physics_process(false)
		Global.player_ref.set_process(false)
		Global.player_ref.sprite.pause()
		
		# 🔥 Player Gayab (Dialogue Mode)
		Global.player_ref.visible = false 
		
	# Enemies Handling
	get_tree().call_group("enemies", "set_physics_process", false)
	get_tree().call_group("enemies", "set_process", false)
	
	Dialogic.start("lvl10")

# --- 6. ENDING TRANSITION ---
func _on_ending_finished():
	print("Ending sequence complete.")
	if Dialogic.timeline_ended.is_connected(_on_ending_finished):
		Dialogic.timeline_ended.disconnect(_on_ending_finished)
	
	AudioManager.stop_music()
	Global.dialogue_playing = false
	
	if next_scene_path:
		TransitionScreen.transition_to(next_scene_path)

# --- 7. VOID LOGIC ---
func _on_void_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(9999, "void")
