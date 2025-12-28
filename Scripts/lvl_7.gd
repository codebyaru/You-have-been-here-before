extends Node2D


# 47 -1 1025 491

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sharperheart - Bittersweet.mp3")
	Global.current_level_id = "lvl7"
	Global.current_level = 7
	WaveHandler.all_waves_completed.connect(_on_waves_done)
	Global.respawn_position = Vector2(14, 258)
	DialogicController.start_dialogue("timeline_4")
	$Beacon.start_timer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta) -> void:
	pass


func _on_void_body_entered(body: Node2D) -> void:
		if body.has_method("player"):
			print("Insatnt death")
			body.take_damage(body.max_health)
		if body.has_method("enemy"):
			body.take_damage(body.MAX_HEALTH)
		if body.has_method("shadow"):
			body.take_damage(body.MAX_HEALTH)

func _on_waves_done(level_id):
	if level_id == "lvl7":
		print("[LEVEL 7] Combat complete")
		# unlock exit
		# continue story
