extends CharacterBody2D

const DEBUG_AI := false

# -----------------------
# CONFIG
# -----------------------
const SPEED := 85.0
const JUMP_VELOCITY := -320.0
const JUMP_COOLDOWN_TIME := 0.6

const ATTACK_RANGE := 40.0
const ATTACK_DAMAGE := 10        # Tick damage
const ATTACK_TICK_RATE := 1.0    # Har 1 sec mein damage
const ATTACK_COOLDOWN := 1.0     # Recovery time
const ATTACK_HITBOX_FRAME := 0.3 # Hitbox activation delay

const MAX_HEALTH := 50

# CRITICAL for Wave Handler
signal died

# -----------------------
# STATE
# -----------------------
enum State { IDLE, FOLLOW, CHASE, ATTACK, ATTACK_RECOVERY, DEAD }

# FIX: Yahan se ": State" hata diya hai
var state = State.IDLE
var previous_state = State.IDLE

var player: CharacterBody2D = null
var target_enemy: CharacterBody2D = null
var health: int = MAX_HEALTH

var jump_cooldown: bool = false

# --- COMBAT VARS (Henchman Style) ---
var attack_can_hit: bool = false
var damage_tick_timer: float = 0.0 
var recovery_timer: float = 0.0

# Track all detected enemies for priority system
var detected_enemies: Array = []

# -----------------------
# NODES
# -----------------------
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ground_check: RayCast2D = $GroundCheck
@onready var wall_check: RayCast2D = $WallCheck
@onready var attack_area: Area2D = $attack_area
@onready var health_bar = $health_bar

# -----------------------
func _ready():
	sprite.play("idle")
	attack_area.monitoring = false
	
	if health_bar:
		health_bar.max_value = MAX_HEALTH
		health_bar.value = MAX_HEALTH
		health_bar.visible = false
	
	if DEBUG_AI: print("[SHADOW] Ready")
	
	call_deferred("_find_initial_player")

func shadow():
	pass

# -----------------------
func _find_initial_player():
	var possible_players = get_tree().get_nodes_in_group("player")
	for p in possible_players:
		if p.has_method("player"):
			player = p
			state = State.FOLLOW
			if DEBUG_AI: print("[SHADOW] Found player: ", p.name)
			return

func set_target(new_player: Node2D):
	if new_player and new_player.has_method("player"):
		player = new_player
		state = State.FOLLOW
		if DEBUG_AI: print("[SHADOW] Player manually assigned")

# -----------------------
func _physics_process(delta: float) -> void:
	if state == State.DEAD: return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# PRIORITY CHECK: Har frame check karo agar naya enemy hai
	_update_target_priority()
	
	# Store previous state for debugging
	if state != previous_state:
		previous_state = state
		if DEBUG_AI: print("[SHADOW] State changed to: ", State.keys()[state])
	
	match state:
		State.IDLE: 
			_idle_state()
		State.FOLLOW:
			_follow_state()
		State.CHASE: 
			_chase_state()
		State.ATTACK: 
			_attack_state(delta)
		State.ATTACK_RECOVERY: 
			_attack_recovery_state(delta)
	
	move_and_slide()

# -----------------------
# PRIORITY SYSTEM
# -----------------------
func _update_target_priority():
	# Cleanup: Invalid enemies ko list se hatao
	detected_enemies = detected_enemies.filter(func(e): return is_instance_valid(e))
	
	# Agar current target invalid hai, reset karo
	if target_enemy != null and not is_instance_valid(target_enemy):
		if DEBUG_AI: print("[SHADOW] Current target died/invalid")
		target_enemy = null
		attack_can_hit = false
		
		# Immediately switch state if in attack-related states
		if state == State.ATTACK or state == State.ATTACK_RECOVERY:
			if detected_enemies.size() > 0:
				state = State.CHASE
			elif player:
				state = State.FOLLOW
			else:
				state = State.IDLE
	
	# Only switch targets if not in attack or recovery
	if state != State.ATTACK and state != State.ATTACK_RECOVERY:
		if detected_enemies.size() > 0:
			var closest_enemy = _get_closest_enemy()
			
			if closest_enemy != null:
				if target_enemy == null:
					target_enemy = closest_enemy
					if state == State.FOLLOW or state == State.IDLE:
						state = State.CHASE
						if DEBUG_AI: print("[SHADOW] New enemy priority: ", closest_enemy.name)
				elif state == State.FOLLOW or state == State.IDLE:
					target_enemy = closest_enemy
					state = State.CHASE
					if DEBUG_AI: print("[SHADOW] Switching to new enemy: ", closest_enemy.name)
		else:
			# No enemies detected
			if target_enemy != null:
				target_enemy = null
				if player != null:
					state = State.FOLLOW
				else:
					state = State.IDLE

func _get_closest_enemy():
	if detected_enemies.size() == 0:
		return null
	
	var closest = null
	var min_dist = INF
	
	for enemy in detected_enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy
	
	return closest

# -----------------------
# STATES
# -----------------------
func _idle_state():
	velocity.x = 0
	if sprite.animation != "idle":
		sprite.play("idle")
	
	# Priority: Enemy > Player
	if detected_enemies.size() > 0:
		state = State.CHASE
	elif player:
		state = State.FOLLOW

func _follow_state():
	if player == null or not is_instance_valid(player):
		state = State.IDLE
		return
	
	var dx: float = player.global_position.x - global_position.x
	var dist_x: float = abs(dx)
	var dir: float = sign(dx)
	
	if dir != 0:
		sprite.flip_h = dir < 0
	
	# Player ke paas (50px) toh ruk jao
	if dist_x < 50:
		velocity.x = 0
		if sprite.animation != "idle":
			sprite.play("idle")
		return
	
	velocity.x = dir * SPEED
	if sprite.animation != "run": 
		sprite.play("run")
	
	# Jump Logic
	ground_check.target_position = Vector2(20.0 * dir, 30.0)
	wall_check.target_position = Vector2(20.0 * dir, 0.0)
	
	if is_on_floor() and not jump_cooldown:
		if not ground_check.is_colliding() or wall_check.is_colliding():
			_do_jump(dir)

func _chase_state():
	# CRITICAL CHECK: Target died/invalid during chase
	if target_enemy == null or not is_instance_valid(target_enemy):
		if DEBUG_AI: print("[SHADOW] Target lost during chase, switching state")
		target_enemy = null
		
		# Immediately decide next action
		if detected_enemies.size() > 0:
			# Aur enemies hain, closest ko target karo
			state = State.CHASE  # Priority system next enemy choose karega
		elif player:
			# Koi enemy nahi, player ko follow karo
			state = State.FOLLOW
		else:
			# Kuch nahi mila, idle ho jao
			state = State.IDLE
		return
	
	var dx: float = target_enemy.global_position.x - global_position.x
	var dist_x: float = abs(dx)
	var dir: float = sign(dx)
	
	if dir != 0:
		sprite.flip_h = dir < 0
	
	# ATTACK TRIGGER - Range mein aate hi attack shuru
	if dist_x <= ATTACK_RANGE:
		_start_attack()
		return
	
	velocity.x = dir * SPEED
	if sprite.animation != "run": 
		sprite.play("run")
	
	# Jump Logic
	ground_check.target_position = Vector2(20.0 * dir, 30.0)
	wall_check.target_position = Vector2(20.0 * dir, 0.0)
	
	if is_on_floor() and not jump_cooldown:
		if not ground_check.is_colliding() or wall_check.is_colliding():
			_do_jump(dir)

# -----------------------
# COMBAT LOGIC (Henchman Style - Continuous Tick)
# -----------------------
func _start_attack():
	state = State.ATTACK
	velocity.x = 0
	sprite.play("attack")
	
	if DEBUG_AI: print("[SHADOW] Attack Start on: ", target_enemy.name if target_enemy else "null")
	
	# Delay ke baad Hitbox ON karo
	get_tree().create_timer(ATTACK_HITBOX_FRAME).timeout.connect(func():
		if state == State.ATTACK:
			attack_can_hit = true
			attack_area.monitoring = true
			damage_tick_timer = 0.0 # Turant damage dene ke liye ready
			if DEBUG_AI: print("[SHADOW] Hitbox Active")
	)
	
	# Animation khatam hone ka wait karo
	await sprite.animation_finished
	
	# Agar abhi bhi attack state mein hai
	if state == State.ATTACK:
		_end_attack()

func _attack_state(delta: float):
	velocity.x = 0 # Attack karte waqt move nahi karega
	
	# CRITICAL CHECK: Target died/invalid during attack
	if target_enemy == null or not is_instance_valid(target_enemy):
		if DEBUG_AI: print("[SHADOW] Target died during attack, switching state")
		attack_can_hit = false
		attack_area.monitoring = false
		
		# Immediately decide next action
		if detected_enemies.size() > 0:
			# Aur enemies hain, chase karo
			state = State.CHASE
		elif player:
			# Koi enemy nahi, player ko follow karo
			state = State.FOLLOW
		else:
			# Kuch nahi mila, idle ho jao
			state = State.IDLE
		return
	
	# Logic: Agar hitbox active hai, toh tick rate ke hisaab se damage do
	if attack_can_hit:
		damage_tick_timer -= delta
		
		if damage_tick_timer <= 0:
			# Check karo kon area mein hai
			var bodies = attack_area.get_overlapping_bodies()
			for body in bodies:
				if body == target_enemy and body.has_method("take_damage"):
					if DEBUG_AI: print("[SHADOW] Dealt ", ATTACK_DAMAGE, " damage to ", body.name)
					body.take_damage(ATTACK_DAMAGE)
					damage_tick_timer = ATTACK_TICK_RATE # Timer reset
					break 
	
	# CANCEL: Agar enemy bohot door chala gaya (Henchman logic)
	if target_enemy and is_instance_valid(target_enemy):
		var dist = abs(target_enemy.global_position.x - global_position.x)
		if dist > ATTACK_RANGE * 1.5:
			if DEBUG_AI: print("[SHADOW] Enemy too far, canceling attack")
			_end_attack()
			state = State.CHASE

func _end_attack():
	attack_can_hit = false
	attack_area.monitoring = false
	recovery_timer = ATTACK_COOLDOWN
	state = State.ATTACK_RECOVERY
	if DEBUG_AI: print("[SHADOW] Recovery Start")

func _attack_recovery_state(delta: float):
	velocity.x = 0
	if sprite.animation != "idle":
		sprite.play("idle")
	
	# CRITICAL CHECK: Target died/invalid during recovery
	if target_enemy != null and not is_instance_valid(target_enemy):
		if DEBUG_AI: print("[SHADOW] Target died during recovery, switching state")
		target_enemy = null
		
		# Immediately decide next action
		if detected_enemies.size() > 0:
			# Aur enemies hain, chase karo
			state = State.CHASE
		elif player:
			# Koi enemy nahi, player ko follow karo
			state = State.FOLLOW
		else:
			# Kuch nahi mila, idle ho jao
			state = State.IDLE
		return
	
	recovery_timer -= delta
	
	if recovery_timer <= 0:
		# Recovery khatam, priority check karo (Henchman style)
		if target_enemy != null and is_instance_valid(target_enemy):
			var dist = abs(target_enemy.global_position.x - global_position.x)
			if dist <= ATTACK_RANGE:
				_start_attack()  # Turant attack agar paas hai
			else:
				state = State.CHASE
		elif detected_enemies.size() > 0:
			# Current target khatam but list mein aur enemies hain
			state = State.CHASE
		elif player:
			state = State.FOLLOW
		else:
			state = State.IDLE

# -----------------------
# HELPERS
# -----------------------
func _do_jump(dir: float):
	jump_cooldown = true
	velocity.y = JUMP_VELOCITY
	velocity.x = dir * SPEED
	sprite.play("jump")
	
	await get_tree().create_timer(JUMP_COOLDOWN_TIME).timeout
	jump_cooldown = false

# -----------------------
# DETECTION - SMART TRACKING
# -----------------------
func _on_detection_body_entered(body: Node2D) -> void:
	# Enemy detect hua
	if body.has_method("enemy") and body != self:
		if not detected_enemies.has(body):
			detected_enemies.append(body)
			if DEBUG_AI: print("[SHADOW] Enemy detected: ", body.name, " | Total enemies: ", detected_enemies.size())
		
		# Immediate priority: Agar idle/follow mein ho toh turant chase
		if state == State.IDLE or state == State.FOLLOW:
			target_enemy = body
			state = State.CHASE
		return
	
	# Player detect hua
	if body.has_method("player"):
		if player == null:
			player = body
			if state == State.IDLE and detected_enemies.size() == 0:
				state = State.FOLLOW
			if DEBUG_AI: print("[SHADOW] Player detected: ", body.name)

func _on_detection_body_exited(body: Node2D) -> void:
	# Enemy left detection
	if body.has_method("enemy") and body != self:
		if detected_enemies.has(body):
			detected_enemies.erase(body)
			if DEBUG_AI: print("[SHADOW] Enemy left: ", body.name, " | Remaining: ", detected_enemies.size())
		
		# Agar yeh current target tha aur attack/recovery nahi chal raha
		if body == target_enemy and state != State.ATTACK and state != State.ATTACK_RECOVERY:
			target_enemy = null
			# Priority system next frame decide karega
	
	# Player left (rare)
	if body == player:
		if DEBUG_AI: print("[SHADOW] Player left detection")

# -----------------------
# DAMAGE & DEATH
# -----------------------
func take_damage(amount: int):
	if state == State.DEAD: return
	
	health -= amount
	health = clamp(health, 0, MAX_HEALTH)
	
	if health_bar:
		health_bar.value = health
		health_bar.visible = true
	
	if DEBUG_AI: print("[SHADOW] Took ", amount, " damage. Health: ", health)
	
	if health <= 0:
		die()

func die():
	state = State.DEAD
	attack_can_hit = false
	velocity = Vector2.ZERO
	if health_bar: health_bar.visible = false
	
	$CollisionShape2D.set_deferred("disabled", true)
	attack_area.set_deferred("monitoring", false)
	
	emit_signal("died")
	
	if DEBUG_AI: print("[SHADOW] Died")
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
		queue_free()
	else:
		await get_tree().create_timer(1.0).timeout
		queue_free()
