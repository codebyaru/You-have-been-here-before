extends Node2D



func _ready() -> void:
	AudioManager.play_music("res://audio/music/VME - Samurai.mp3")
	Global.current_level_id = "lvl4"
	Global.current_level = 4
	WaveHandler.all_waves_completed.connect(_on_waves_done)
	Global.respawn_position =  Vector2(14, 258)
	Dialogic.start("lvl4_start")


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
	if level_id == "lvl4":
		print("[LEVEL 2] Combat complete")
		# unlock exit
		# continue story
