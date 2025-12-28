extends Node2D


# 47 -1 1025 491

func _ready() -> void:
	print("========================================")
	print("[LEVEL 3] _ready() called - Scene loaded!")
	print("[LEVEL 3] Current Global.current_level =", Global.current_level)
	print("[LEVEL 3] AudioManager exists? ", AudioManager != null)
	print("[LEVEL 3] AudioManager.music_player exists?", AudioManager.music_player != null)
	print("========================================")
	
	AudioManager.play_music("res://audio/music/VME - Samurai.mp3")
	
	Global.current_level_id = "lvl3"
	Global. current_level = 3
	WaveHandler.all_waves_completed.connect(_on_waves_done)
	Global.respawn_position = Vector2(14, 258)
	
	# Check if music is actually playing after a small delay
	await get_tree().create_timer(0.5).timeout
	print("[LEVEL 3] After 0.5s - music_player.playing =", AudioManager.music_player.playing)
	print("[LEVEL 3] After 0.5s - music_player.stream =", AudioManager.music_player.stream)
	
	#DialogicController.start_dialogue("timeline_4")
	#$Beacon.start_timer()

# Called every frame.  'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass


func _on_void_body_entered(body:  Node2D) -> void:
		if body.has_method("player"):
			print("Insatnt death")
			body.take_damage(body.max_health)
		if body.has_method("enemy"):
			body.take_damage(body.MAX_HEALTH)
		if body.has_method("shadow"):
			body.take_damage(body. MAX_HEALTH)

func _on_waves_done(level_id):
	if level_id == "lvl3":
		print("[LEVEL 3] Combat complete")
		# unlock exit
		# continue story
