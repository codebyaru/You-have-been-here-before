extends Node

signal waves_started(level_id)
signal wave_completed(wave_index)
signal all_waves_completed(level_id)

var active := false
var current_level := ""
var current_wave := 0
var enemies_alive := 0
var boss_active := false # Track agar hum boss fight mein hain

var spawn_points: Array = []

# -----------------------
# WAVE CONFIG
# -----------------------

var level_waves := {
	"lvl2": {
		"enemy_scene": preload("res://Scenes/enemies/henchmen.tscn"),
		"boss_scene": preload("res://Scenes/enemies/demon_slime.tscn"), # BOSS SCENE YAHAN DALNA
		"waves": [3, 5,7] 
	},
	"lvl3": {
		"enemy_scene": preload("res://Scenes/enemies/henchmen.tscn"),
		"boss_scene": preload("res://Scenes/enemies/mecha_golem.tscn"), # BOSS SCENE YAHAN DALNA
		"waves": [ 5,7,10] 
	},
	"lvl5": {
		"enemy_scene": preload("res://Scenes/enemies/henchmen.tscn"),
		"boss_scene": preload("res://Scenes/enemies/Frost_Guardian.tscn"), # BOSS SCENE YAHAN DALNA
		"waves": [ 5,7,10]
	},

	"lvl9": {
		"enemy_scene": preload("res://Scenes/enemies/henchmen.tscn"),
		"boss_scene": preload("res://Scenes/enemies/Undead_Excecutiner.tscn"), # BOSS SCENE YAHAN DALNA
		"waves": [ 5,10,10,10] 
	},
	"lvl7": {
		"enemy_scene": preload("res://Scenes/enemies/henchmen.tscn"),
		"boss_scene": preload("res://Scenes/enemies/Minotaur.tscn"), # BOSS SCENE YAHAN DALNA
		"waves": [ 5,7,10,12]
	}
	
}

# -----------------------
# ENTRY POINT
# -----------------------

func start_level_waves(level_id: String):
	if active:
		print("[WAVE] Already running, ignoring")
		return

	if not level_waves.has(level_id):
		push_error("[WAVE] No wave config for " + level_id)
		return

	active = true
	boss_active = false
	current_level = level_id
	current_wave = 0

	print("[WAVE] Starting waves for", level_id)
	emit_signal("waves_started", level_id)

	_collect_spawn_points()
	_start_next_wave()


func _collect_spawn_points():
	spawn_points.clear()
	var level := get_tree().current_scene
	var spawners := level.get_node_or_null("Spawners")

	if spawners == null:
		push_error("[WAVE] No 'Spawners' node found in level")
		return

	for child in spawners.get_children():
		if child is Marker2D:
			spawn_points.append(child)

# -----------------------
# WAVE LOGIC
# -----------------------

func _start_next_wave():
	var config = level_waves[current_level]
	var waves_list = config["waves"]

	# Check: Agar saari normal waves khatam ho gayi hain
	if current_wave >= waves_list.size():
		if not boss_active:
			_start_boss_wave() # Ab Boss ki baari
		return

	# --- NORMAL WAVE ---
	var count = waves_list[current_wave]
	print("[WAVE] Starting Wave", current_wave + 1)
	
	# 1. Play Dialogue (Wave_1, Wave_2, etc.)
	var dialog_key = "Wave_" + str(current_wave + 1)
	_play_dialogue(dialog_key)
	
	# 2. Spawn Enemies
	enemies_alive = count
	for i in count:
		_spawn_enemy(config["enemy_scene"])

	current_wave += 1

func _start_boss_wave():
	print("[WAVE] ⚠️ BOSS WAVE STARTED ⚠️")
	boss_active = true
	enemies_alive = 1 # Boss is 1 enemy
	
	# 1. Play Boss Dialogue
	_play_dialogue("boss_wave")
	
	# 2. Spawn Boss
	var config = level_waves[current_level]
	if config.has("boss_scene"):
		_spawn_enemy(config["boss_scene"], true) # true = is_boss
	else:
		push_error("[WAVE] Boss scene missing in config!")
		_finish_all_waves() # Skip if no boss

# -----------------------
# SPAWNING
# -----------------------

func _spawn_enemy(scene_resource, is_boss: bool = false):
	if spawn_points.is_empty(): return

	var enemy = scene_resource.instantiate()
	var spawn = spawn_points.pick_random()
	
	enemy.global_position = spawn.global_position
	get_tree().current_scene.add_child(enemy)

	# Connect death signal
	enemy.died.connect(_on_entity_died)
	
	if is_boss:
		# Optional: Boss ko thoda scale ya effect de sakte ho yahan
		print("[WAVE] Boss Spawned: ", enemy.name)

# -----------------------
# COMPLETION LOGIC
# -----------------------

func _on_entity_died():
	enemies_alive -= 1
	print("[WAVE] Entity died. Remaining:", enemies_alive)

	if enemies_alive <= 0:
		if boss_active:
			# Agar Boss mar gaya -> LEVEL COMPLETE
			_finish_all_waves()
		else:
			# Agar Normal wave khatam hui -> NEXT WAVE
			print("[WAVE] Wave completed")
			emit_signal("wave_completed", current_wave)
			
			# Thoda wait karo agli wave se pehle
			await get_tree().create_timer(2.0).timeout
			_start_next_wave()
func _finish_all_waves():
	print("[WAVE] 🎉 ALL WAVES & BOSS DEFEATED 🎉")
	
	active = false
	boss_active = false
	
	# --- 1. UPDATE GLOBAL PROGRESS (UNLOCK MAGIC) ---
	# Global ko batao ki humne ye level ka boss hara diya hai
	Global.max_level=Global.current_level
	
	# --- 2. PLAY REWARD DIALOGUE ---
	# "new_magic" dialogue chalega jo player ko batayega ki nayi power mili hai
	print("[DIALOGUE] Playing Magic Unlock Dialogue")
	# Agar dialogue wait karna hai to 'await' use kar sakte ho
	await _play_dialogue("new_magic") 
	
	# --- 3. PLAY END LEVEL DIALOGUE ---
	# Thoda ruk kar level end ka dialogue (optional, agar alag hai to)
	await get_tree().create_timer(1.0).timeout
	_play_dialogue("Wave_ended")
	
	# --- 4. MARK COMPLETE & SIGNAL ---
	Global.completed_levels[current_level] = true
	emit_signal("all_waves_completed", current_level)

# -----------------------
# HELPER (Updated for async/await)
# -----------------------
func _play_dialogue(timeline_key: String):
	if true: # Check if Dialogic exists logic
		print("[DIALOGUE] Playing:", timeline_key)
		Dialogic.start(timeline_key)
		
		# Wait for dialogue to finish logic (Dialogic specific)
		# Agar tum chahte ho code ruke jab tak dialogue chal raha hai:
		# await Dialogic.timeline_ended
		# Note: Ye tabhi chalega agar Dialogic 2.0+ correctly setup hai.
		# Agar simple rakhna hai to bas start karo aur return karo:
		return 
	else:
		print("[DIALOGUE] Dialogic not found, skipping:", timeline_key)
