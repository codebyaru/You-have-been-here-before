extends AnimatedSprite2D

@export var beacon_id := "lvl2_beacon_1"

var player_near := false
var activated := false
var bounce_tween: Tween

@onready var prompt: Label = $Label
@onready var area: Area2D = $Area2D

var base_y := 0.0

# -----------------------
# -----------------------
# INITIALIZATION
# -----------------------
func _ready():
	prompt.visible = false
	base_y = prompt.position.y

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	Dialogic.signal_event.connect(_on_dialogic_signal)
	self.play("default")
	
	# 🔥 FIX 1: Shuru mein Process band kar do taaki Input check hi na ho
	set_process(false) 
	
	# 1.5 second ka delay (Safety Buffer)
	await get_tree().create_timer(1.5).timeout
	
	# Ab Input check chalu karo
	set_process(true)
	
	# Agar Player already upar khada hai (Spawn issue), toh prompt dikha do
	if area.get_overlapping_bodies().any(func(b): return b.has_method("player")):
		player_near = true
		prompt.visible = true
		start_bounce()

	print("[BEACON]", beacon_id, "ready (Input Unlocked)")

# -----------------------
# INPUT
# -----------------------
func _process(_delta):
	# Ab yahan extra variable ki zarurat nahi, set_process handle kar lega
	if player_near and not activated and Input.is_action_just_pressed("interact"):
		activate_beacon()
# -----------------------
# DIALOGIC
# -----------------------
func _on_dialogic_signal(arg: String):
	if arg != "fight_start":
		return

	print("[BEACON]", beacon_id, "→ fight_start received")
	self.play("activated")
	var level_id: String = Global.current_level_id
	if level_id == "":
		push_error("[BEACON] No current level set")
		return

	print("[BEACON]", beacon_id, "→ starting waves for", level_id)
	WaveHandler.start_level_waves(level_id)



# -----------------------
# AREA EVENTS
# -----------------------
func _on_body_entered(body):
	if body.has_method("player"):
		

		player_near = true
		prompt.visible = true
		start_bounce()

	if not activated:
		play("idle")
		print("[BEACON]", beacon_id, "idle ON")

func _on_body_exited(body):
	if body.has_method("player"):
		player_near = false
		prompt.visible = false
		stop_bounce()
		self.play("default")

	# IMPORTANT: allow re-use after leaving area
		activated = false

		print("[BEACON]", beacon_id, "idle OFF / reset")

# -----------------------
# CORE LOGIC
# -----------------------
func activate_beacon():
	activated = true
	prompt.visible = false
	stop_bounce()
	stop()

	increment_access_count()
	var access_count := get_access_count()

	print("[BEACON]", beacon_id, "activated | access =", access_count)

	# FIRST ACCESS → QUEST / FIGHT
	if access_count % 2 ==  1:
		access_count = 2
		print("[BEACON] First access → dialogue")
		start_dialogue_for_level()
		return

	# AFTER QUEST COMPLETED → ADVANCE
	if Global.completed_levels.get(Global.current_level_id, false):
		print("[BEACON] Level completed → advancing")
		advance_level()
		return

	print("[BEACON] No action available yet")

# -----------------------
# DIALOGUE
# -----------------------
func start_dialogue_for_level():
	match Global.current_level:
		2:
			run_dialogue("lvl2")
		3:
			run_dialogue("lvl3")
		4:
			
			run_dialogue("lvl4") 
		5:
			run_dialogue("lvl5")
		7:
			run_dialogue("lvl7")
		9:
			run_dialogue("lvl9")
		10:
			# run_dialogue("lvl10")
			pass
		_:
			# run_dialogue("default")
			pass

func run_dialogue(dialogue_string: String):
	print("[BEACON] Dialogue start:", dialogue_string)

	Global.dialogue_playing = true
	Dialogic.start(dialogue_string)

	if not Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	Global.dialogue_playing = false
	print("[BEACON] Dialogue finished")

	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)
	
	# --- 🔥 LEVEL 4 SPECIAL EXCEPTION 🔥 ---
	# Agar level 4 hai, toh fight ka wait mat karo, seedha teleport karo
	if Global.current_level == 4:
		print("[BEACON] Level 4 Special: Skipping fight, teleporting directly.")
		advance_level()

# -----------------------
# BOUNCE PROMPT
# -----------------------
func start_bounce():
	stop_bounce()

	bounce_tween = create_tween()
	bounce_tween.set_loops()

	bounce_tween.tween_property(
		prompt,
		"position:y",
		base_y - 6,
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	bounce_tween.tween_property(
		prompt,
		"position:y",
		base_y,
		0.6
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func stop_bounce():
	if bounce_tween:
		bounce_tween.kill()
		bounce_tween = null
	prompt.position.y = base_y

# -----------------------
# GLOBAL STATE HELPERS
# -----------------------
func get_access_count() -> int:
	return Global.beacon_access_count.get(beacon_id, 0)

func increment_access_count():
	Global.beacon_access_count[beacon_id] = get_access_count() + 1

func advance_level():
	print("[BEACON] Level completed. Calling Global to switch scenes...")
	
	# Sirf ye line chahiye ab. Logic Global sambhalega.
	Global.proceed_to_next_level()

	# Scene change later
	# get_tree().change_scene_to_file(...)
