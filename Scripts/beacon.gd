extends AnimatedSprite2D

@export var beacon_id := "lvl2_beacon_1"

var player_near := false
var activated := false
var bounce_tween: Tween

# 🔥 NEW: Local variable, hamesha 0 se start hoga jab scene load hogi
var local_interaction_count := 0

@onready var prompt: Label = $Label
@onready var area: Area2D = $Area2D

var base_y := 0.0

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
	
	set_process(false) 
	await get_tree().create_timer(1.5).timeout
	set_process(true)
	
	if area.get_overlapping_bodies().any(func(b): return b.has_method("player")):
		player_near = true
		prompt.visible = true
		start_bounce()

	print("[BEACON]", beacon_id, "ready (Local Count: 0)")

# -----------------------
# INPUT
# -----------------------
func _process(_delta):
	if player_near and not activated and Input.is_action_just_pressed("interact"):
		activate_beacon()

# -----------------------
# DIALOGIC SIGNAL (Fight Starter)
# -----------------------
func _on_dialogic_signal(arg: String):
	if arg != "fight_start":
		return

	print("[BEACON] Fight Start Signal Received")
	self.play("activated")
	
	var level_id: String = Global.current_level_id
	if level_id != "":
		WaveHandler.start_level_waves(level_id)

# -----------------------
# CORE LOGIC (LOCAL & FIXED)
# -----------------------
func activate_beacon():
	activated = true
	prompt.visible = false
	stop_bounce()
	stop()

	# 1. LOCAL COUNT INCREMENT
	local_interaction_count += 1
	print("[BEACON] Activated. Local Count: ", local_interaction_count)

	# 2. CHECK SAFE LEVELS (4, 6, 8) -> Immediate Dialogue & Advance
	if Global.current_level == 4 or Global.current_level == 6 or Global.current_level == 8:
		print("[BEACON] Safe Level detected. Starting dialogue sequence...")
		start_dialogue_for_level()
		return

	# 3. NORMAL LEVELS - 1st INTERACTION (Start Fight)
	if local_interaction_count == 1:
		print("[BEACON] 1st Contact -> Starting Dialogue/Fight")
		start_dialogue_for_level()
		return

	# 4. NORMAL LEVELS - 2nd+ INTERACTION (Advance if Won)
	if local_interaction_count >= 2:
		if Global.completed_levels.get(Global.current_level_id, false):
			print("[BEACON] 2nd Contact & Level Complete -> Advancing")
			advance_level()
		else:
			print("[BEACON] Level NOT complete yet. Finish the fight!")
			# Optional: Reset count to 1 taaki player wapas click kare to dialogue na aaye?
			# Ya bas ignore karein. Abhi ke liye ignore kar rahe hain.
			activated = false # Allow clicking again immediately if stuck

# -----------------------
# DIALOGUE HANDLER
# -----------------------
func start_dialogue_for_level():
	match Global.current_level:
		2: run_dialogue("lvl2")
		3: run_dialogue("lvl3")
		4: run_dialogue("lvl4") 
		5: run_dialogue("lvl5")
		7: run_dialogue("lvl7")
		8: run_dialogue("lvl8")
		9: run_dialogue("lvl9")
		10: pass 
		_: _on_dialogue_finished() # Agar koi dialogue nahi hai to seedha finish call karo

func run_dialogue(dialogue_string: String):
	Global.dialogue_playing = true
	Dialogic.start(dialogue_string)

	if not Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.connect(_on_dialogue_finished)

func _on_dialogue_finished():
	Global.dialogue_playing = false
	print("[BEACON] Dialogue finished")

	if Dialogic.timeline_ended.is_connected(_on_dialogue_finished):
		Dialogic.timeline_ended.disconnect(_on_dialogue_finished)
	
	# --- SAFE LEVEL AUTO-ADVANCE ---
	# Levels 4, 6, 8 mein fight nahi hoti, to dialogue khatam hote hi advance karo
	if Global.current_level == 4 or Global.current_level == 6 or Global.current_level == 8:
		print("[BEACON] Safe Level Dialogue Done. Marking Complete & Advancing.")
		Global.completed_levels[Global.current_level_id] = true 
		advance_level()

# -----------------------
# HELPER: ADVANCE LEVEL
# -----------------------
func advance_level():
	print("[BEACON] Proceeding to next level...")
	Global.proceed_to_next_level()

# -----------------------
# AREA EVENTS & ANIMATION
# -----------------------
func _on_body_entered(body):
	if body.has_method("player"):
		player_near = true
		prompt.visible = true
		start_bounce()

	if not activated:
		play("idle")

func _on_body_exited(body):
	if body.has_method("player"):
		player_near = false
		prompt.visible = false
		stop_bounce()
		self.play("default")
		
		# Allow Reset
		activated = false

# -----------------------
# BOUNCE TWEEN
# -----------------------
func start_bounce():
	stop_bounce()
	bounce_tween = create_tween()
	bounce_tween.set_loops()
	bounce_tween.tween_property(prompt, "position:y", base_y - 6, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bounce_tween.tween_property(prompt, "position:y", base_y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func stop_bounce():
	if bounce_tween:
		bounce_tween.kill()
		bounce_tween = null
	prompt.position.y = base_y
