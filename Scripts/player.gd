extends CharacterBody2D

# -----------------------
# AUDIO CONFIG
# -----------------------
# I found these actual files in your project folder:
const ATTACK_SOUND_PATH = "res://audio/SFX/attack-release-384909.mp3"
const HURT_SOUND_PATH = "res://audio/SFX/bulletimpact2-442718.mp3"

# -----------------------
# CONFIG
# -----------------------
const SPEED = 100.0
const DASH_SPEED = 300.0
const SUPER_SPRINT_SPEED = 600.0
const JUMP_VELOCITY = -350.0
var GRAVITY = 1200.0

# --- 🔥 SCALING CONFIG ---
var base_scale: Vector2 
const SP_SCALE_MULT = 0.1 

# --- 🔥 DAMAGE CONFIG (BALANCED) ---
var current_attack_damage = 0 
var is_special_attack_active = false 

# Updated Values: Ab normal attacks fixed 20-35 range mein hain
const DAMAGE_VALUES = {
	"attack-I": 20,
	"attack-II": 30,
	"dash_attack": 25,
	"jump_up_attack": 25,
	"jump_down_attack": 35,
	"SPattack": 0 # Logic override karega (50% HP)
}

# Attack Hitbox Timings
const ATTACK_TIMINGS = {
	"attack-I": 0.2,
	"attack-II": 0.25,
	"dash_attack": 0.15,
	"jump_up_attack": 0.2,
	"jump_down_attack": 0.2,
	"SPattack": 0.9 
}

# --- SPECIAL ATTACK VARS ---
const SPECIAL_COOLDOWN_TIME = 0
var special_timer = 0.0
var is_special_ready = true

# Health Config
var max_health = 500
var current_health = 500
var is_dead = false
var max_mana := 300
var current_mana := 300

const HEALTH_REGEN_PERCENT := 0.1  # 10%
const MANA_REGEN_PERCENT := 0.07     # 7%
const REGEN_INTERVAL := 0.2

var regen_timer := 2
# Combat States
var is_attacking = false
var attack_timer = 0.0
var attack_can_hit = false
var combo_count = 0

var direction
# Nodes
@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $health_bar
@onready var mana_bar = $mana_bar
@onready var attack_area = $attack_area

@onready var ability_component: PlayerUseAbilityComponent = $PlayerUseAbilityComponent
@onready var lvl2_camera = $lvl2_camera
@onready var lvl4_camera = $lvl4_camera
@onready var lvl6_camera = $lvl6_camera

var is_critical_health: bool = false # 🔥 New variable for your dialogue check


const MAGIC_MANA_COST := {
	"fire_spin": 12,
	"fire_ball": 5,
	"water_ball": 8,
	"rock_throw": 10,
	"wind_tornado": 15,
	"shadow_summon": 50
}

# -----------------------
# INITIALIZATION
# -----------------------
func _ready():
	Global.player_ref = self
	
	# --- CHECK FOR LOAD DATA ---
	if Global.load_health != -1:
		print("[PLAYER] Loading saved state...")
		current_health = Global.load_health
		current_mana = Global.load_mana
		global_position = Global.load_position
		
		# Reset Global load vars so next restart doesn't glitch
		Global.load_health = -1 
		Global.load_mana = -1
		Global.load_position = Vector2.ZERO
	# ---------------------------

	health_bar.init_health(max_health)
	health_bar.set_health(current_health) # Update UI immediately
	
	ability_component.magic_used.connect(_on_magic_used)
	mana_bar.max_value = max_mana
	mana_bar.init_mana(max_mana)
	mana_bar.set_mana(current_mana) # Update UI immediately
	
	base_scale = sprite.scale
	print("[SETUP] Player Base Scale captured: ", base_scale)

	if attack_area:
		attack_area.monitoring = false

func _process(_delta: float) -> void:
	update_camera_based_on_level()
	
func _on_magic_used(attack_name: String) -> void:
	if not MAGIC_MANA_COST.has(attack_name):
		return

	var cost :int = MAGIC_MANA_COST[attack_name]

	if current_mana < cost:
		print("[PLAYER] ❌ Not enough mana for", attack_name)
		return

	current_mana -= cost
	mana_bar.set_mana(current_mana)

	print("[PLAYER] 🔵 Mana -", cost, "(", attack_name, ")")

func player():
	pass
func get_current_mana() -> int:
	return current_mana

# -----------------------
# PHYSICS LOOP
# -----------------------
func _physics_process(delta: float) -> void:
	if Global.dialogue_playing or is_dead:
		velocity.x = move_toward(velocity.x, 0, 15)
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_handle_cooldowns(delta)

	direction = Input.get_axis("ui_left", "ui_right")
	if Input.is_key_pressed(KEY_A): direction = -1
	elif Input.is_key_pressed(KEY_D): direction = 1
	
	var current_speed = SPEED
	var is_dashing = false
	var is_super = false

	if direction != 0:
		if Input.is_key_pressed(KEY_SHIFT) and (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)):
			current_speed = SUPER_SPRINT_SPEED
			is_super = true
		elif Input.is_key_pressed(KEY_SHIFT):
			current_speed = DASH_SPEED
			is_dashing = true

	# --- ATTACK INPUTS ---
	if not is_attacking:
		if Input.is_action_just_pressed("attack"):
			if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_S):
				if is_special_ready:
					perform_special_attack()
				else:
					print("[PLAYER] ⏳ Special on Cooldown!")
			else:
				perform_normal_attack(is_dashing)

	# --- MOVEMENT APPLICATION ---
	if not is_attacking:
		if direction != 0:
			velocity.x = direction * current_speed
			sprite.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
		if Input.is_key_pressed(KEY_W) and is_on_floor():
			velocity.y = JUMP_VELOCITY
			
		update_animations(direction, is_dashing, is_super)
	else:
		velocity.x = move_toward(velocity.x, 0, 15)

	move_and_slide()

# -----------------------
# COOLDOWNS & RESET
# -----------------------
func _handle_cooldowns(delta):
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			# Reset Combat Flags
			is_attacking = false
			attack_timer = 0
			attack_can_hit = false
			is_special_attack_active = false 
			
			if attack_area: attack_area.monitoring = false
			
			if sprite.scale != base_scale:
				sprite.scale = base_scale
				sprite.modulate = Color.WHITE
				print("[PLAYER] Resetting Scale to Base: ", base_scale)

	regen_timer += delta
	if regen_timer >= REGEN_INTERVAL:
		regen_timer = 0
		_regenerate_health()
		_regenerate_mana()

	if not is_special_ready:
		special_timer -= delta
		if special_timer <= 0:
			is_special_ready = true
			print("[PLAYER] 🔥 ULTIMATE READY!")
			var tween = create_tween()
			tween.tween_property(sprite, "modulate", Color(1, 0.8, 0, 1), 0.2)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

# -----------------------
# COMBAT SYSTEM
# -----------------------

func _regenerate_health():
	if is_dead or is_attacking:
		return
	if current_health >= max_health:
		return

	var regen_amount = int(max_health * HEALTH_REGEN_PERCENT)
	current_health = min(current_health + regen_amount, max_health)
	health_bar.set_health(current_health)

	print("[REGEN] ❤️ Health +", regen_amount)

func _regenerate_mana():
	if current_mana >= max_mana:
		return
	
	var regen_amount = int(max_mana * MANA_REGEN_PERCENT)
	current_mana = min(current_mana + regen_amount, max_mana)
	
	mana_bar.set_mana(current_mana) 

	print("[REGEN] 🔵 Mana +", regen_amount)

func perform_normal_attack(dashing):
	is_attacking = true
	attack_can_hit = false
	is_special_attack_active = false # Normal fixed damage logic apply hoga
	
	# --- 🔊 AUDIO ADDED HERE ---
	AudioManager.play_sfx(ATTACK_SOUND_PATH)
	# ---------------------------
	
	sprite.scale = base_scale 
	
	var anim = ""
	var dur = 0.6
	var dmg = 0

	if not is_on_floor():
		if Input.is_key_pressed(KEY_S):
			anim = "jump_down_attack"
			dmg = DAMAGE_VALUES["jump_down_attack"]
		else:
			anim = "jump_up_attack"
			dmg = DAMAGE_VALUES["jump_up_attack"]
		dur = 0.5
	else:
		if dashing:
			anim = "dash_attack"
			dur = 0.4
			dmg = DAMAGE_VALUES["dash_attack"]
		else:
			anim = "attack-I" if combo_count == 0 else "attack-II"
			dmg = DAMAGE_VALUES[anim]
			combo_count = 1 - combo_count

	current_attack_damage = dmg
	attack_timer = dur
	sprite.play(anim)
	
	var hitbox_timing = ATTACK_TIMINGS.get(anim, 0.2)
	_schedule_hitbox_activation(hitbox_timing)
	
	print("[PLAYER] Normal Atk: ", anim, " | Dmg: ", dmg)

func perform_special_attack():
	is_attacking = true
	attack_can_hit = false
	is_special_ready = false
	is_special_attack_active = true # 🔥 50% Damage logic enable
	
	special_timer = SPECIAL_COOLDOWN_TIME
	
	var anim = "SPattack"
	current_attack_damage = 0 
	attack_timer = 1.2 
	
	print("[PLAYER] ⚠️ SP ATTACK START! Base Scale: ", base_scale)
	sprite.play(anim)
	
	# --- 🔊 AUDIO ADDED HERE ---
	# Playing the same attack sound, but you can change this to a unique special sound later
	AudioManager.play_sfx(ATTACK_SOUND_PATH)
	# ---------------------------
	
	sprite.scale = base_scale * SP_SCALE_MULT
	print("[PLAYER] 🔻 Shrinking Sprite to: ", sprite.scale)
	
	_schedule_hitbox_activation(ATTACK_TIMINGS["SPattack"])

# -----------------------
# HITBOX LOGIC
# -----------------------
func _schedule_hitbox_activation(delay: float):
	await get_tree().create_timer(delay).timeout
	
	if is_attacking:
		attack_can_hit = true
		if attack_area:
			attack_area.monitoring = true
		print("[PLAYER] Hitbox ACTIVE")

func _on_attack_area_body_entered(body: Node2D) -> void:
	if is_attacking and attack_can_hit and body.has_method("take_damage"):
		
		var final_damage = current_attack_damage
		
		# 🔥 SPECIAL ATTACK LOGIC: 50% of Enemy MAX HP
		if is_special_attack_active:
			if "MAX_HEALTH" in body:
				var enemy_max_hp = body.MAX_HEALTH
				# Updated to 50% as requested
				final_damage = int(enemy_max_hp * 0.50) 
				print("[PLAYER] 💥 ULTIMATE HIT! Enemy Max HP: ", enemy_max_hp, " | Dmg: ", final_damage)
			else:
				final_damage = 200 # Fallback
		
		print("[PLAYER] Hit Enemy! Final Dealt: ", final_damage)
		body.take_damage(final_damage)
		
		attack_can_hit = false
		if attack_area:
			attack_area.monitoring = false

# -----------------------
# DAMAGE TAKING
# -----------------------
func take_damage(amount: int, damage_source: String = "physical"):
	if is_dead: return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	health_bar.set_health(current_health)
	
	# --- 🔊 AUDIO ADDED HERE ---
	AudioManager.play_sfx(HURT_SOUND_PATH)
	# ---------------------------

	# --- 🔥 LOGIC UPDATE START ---
	
	# 1. Handle Visuals based on Source
	if damage_source == "void":
		# Void damage: Shayad hum hit animation na play karein, bas screen fade ho ya instant respawn logic ho
		print("[PLAYER] Fell into VOID")
		is_critical_health = false # Void shouldn't trigger "I'm injured" dialogue
	else:
		# Combat damage (physical/magic)
		sprite.modulate = Color(1, 0.3, 0.3)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
		sprite.play("hit")
		print("[player] took damage: " , amount," viva ",damage_source)
		# 2. Check for Critical Health (10% or below) ONLY for Combat
		var threshold = max_health * 0.10 # 10% calc
		
		if  current_health <= threshold and Global.current_level==10:
			if not is_critical_health: # Taaki baar baar true set na karein
				is_critical_health = true
				print("[PLAYER] ⚠️ CRITICAL HEALTH! (Combat Induced)")
				get_parent()._trigger_critical_sequence()
				# Yahan tum signal emit kar sakte ho ya dialogue manager check kar lega
				# emit_signal("player_critical") 
		else:
			# Agar health heal ho gayi ya abhi threshold se upar hai
			is_critical_health = false

	# --- LOGIC UPDATE END ---

	if current_health <= 0:
		die()

func apply_knockback(force_vector: Vector2):
	velocity = force_vector
	move_and_slide()
	sprite.modulate = Color(1, 0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

# -----------------------
# ANIMATION & DEATH
# -----------------------
func update_animations(direction, is_dashing, is_super):
	if is_on_floor():
		if direction != 0:
			if is_super: sprite.play("super_sprint")
			elif is_dashing: sprite.play("dash")
			else: sprite.play("run")
		else:
			sprite.play("Idle")
	else:
		if velocity.y < 0: sprite.play("jump")
		elif velocity.y > 150: sprite.play("fall")
		else: sprite.play("mid_air")

func die():
	if is_dead: return
	is_dead = true
	is_critical_health = false # Marne ke baad critical status reset
	current_health = 0
	health_bar.set_health(0)

	GRAVITY = 0
	velocity = Vector2.ZERO
	sprite.play("death")
	set_physics_process(false)
	await get_tree().create_timer(.5).timeout
	respawn()
	
func respawn():
	print("[PLAYER] 🔁 RESPAWN")

	is_dead = false
	is_critical_health = false # Reset status
	current_health = max_health
	current_mana = max_mana

	if not is_instance_valid(health_bar):
		health_bar = $health_bar
	if not is_instance_valid(mana_bar):
		mana_bar = $mana_bar

	health_bar.init_health(max_health)
	mana_bar.init_mana(max_mana)
	
	GRAVITY = 1200.0
	velocity = Vector2.ZERO
	set_physics_process(true)

	sprite.modulate = Color.WHITE
	sprite.scale = base_scale
	sprite.play("Idle")

	if Global.respawn_position != Vector2.ZERO:
		global_position = Global.respawn_position


func update_camera_based_on_level():
	# Agar level 4 hai
	if Global.current_level == 4 or Global.current_level == 5 :
		# Check karo agar already level 4 ka camera active nahi hai tabhi switch karo
		if not lvl4_camera.is_current():
			lvl4_camera.make_current()
			print("[CAMERA] Switched to Level 4 Camera")
	if Global.current_level == 6:
		if not lvl6_camera.is_current():
			lvl6_camera.make_current()
			print("[CAMERA] Switched to Level 4 Camera")
	# Future ke liye: Jab level 2 ka logic lagana ho toh yahan 'elif' aa jayega
	# elif Global.current_level == 2:
	# 	  if not lvl2_camera.is_current():
	#         lvl2_camera.make_current()
