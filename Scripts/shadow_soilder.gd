extends CharacterBody2D

const DEBUG_AI := true

# -----------------------
# CONFIG
# -----------------------
const SPEED := 85.0
const JUMP_VELOCITY := -320.0
const JUMP_COOLDOWN_TIME := 0.6

const ATTACK_RANGE := 40.0
const ATTACK_DAMAGE := 20
const ATTACK_COOLDOWN := 1.0
const DEATH_ANIMATION_TIME := 1.0

const MAX_HEALTH := 50

# CRITICAL for Wave Handler
signal died

# -----------------------
# STATE
# -----------------------
enum State { IDLE, FOLLOW, CHASE, ATTACK, ATTACK_RECOVERY, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D = null
var target_enemy: CharacterBody2D = null
var health: int = MAX_HEALTH

var jump_cooldown: bool = false
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
	
	health_bar.max_value = MAX_HEALTH
	health_bar.value = MAX_HEALTH
	health_bar.visible = false
	
	if DEBUG_AI: print("[SHADOW] Ready")
	
	call_deferred("_find_initial_player")

func shadow():
	pass

func enemy():
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
	
	match state:
		State.IDLE: 
			_idle_state()
		State.FOLLOW:
			_follow_state()
		State.CHASE: 
			_chase_state()
		State.ATTACK: 
			_attack_state()
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
		target_enemy = null
		if DEBUG_AI: print("[SHADOW] Current target died/invalid")
	
	# PRIORITY LOGIC:
	# 1. Agar koi enemy hai list mein aur abhi koi target nahi
	# 2. Ya agar attack/chase state nahi hai aur enemy mil gaya
	if detected_enemies.size() > 0:
		# Closest enemy dhundo
		var closest_enemy = _get_closest_enemy()
		
		# Agar naya closest enemy hai aur hum attack mein busy nahi
		if closest_enemy != null:
			if target_enemy == null:
				# Pehli baar enemy mila
				target_enemy = closest_enemy
				if state == State.FOLLOW or state == State.IDLE:
					state = State.CHASE
					if DEBUG_AI: print("[SHADOW] New enemy priority: ", closest_enemy.name)
			elif state == State.FOLLOW or state == State.IDLE:
				# Follow/Idle mein ho aur naya enemy detect hua
				target_enemy = closest_enemy
				state = State.CHASE
				if DEBUG_AI: print("[SHADOW] Switching to new enemy: ", closest_enemy.name)
	else:
		# Koi enemy nahi, player ko follow karo
		if target_enemy != null and state != State.ATTACK and state != State.ATTACK_RECOVERY:
			target_enemy = null
			if player != null:
				state = State.FOLLOW
				if DEBUG_AI: print("[SHADOW] No enemies, back to follow")

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
	sprite.play("idle")
	
	# Priority: Enemy > Player
	if detected_enemies.size() > 0:
		state = State.CHASE
	elif player:
		state = State.FOLLOW

func _follow_state():
	# Priority check already handled in _update_target_priority()
	
	if player == null or not is_instance_valid(player):
		state = State.IDLE
		return
	
	var dx: float = player.global_position.x - global_position.x
	var dist_x: float = abs(dx)
	var dir: float = sign(dx)
	
	sprite.flip_h = dir < 0
	
	# Player ke paas (50px) toh ruk jao
	if dist_x < 50:
		velocity.x = 0
		sprite.play("idle")
		return
	
	velocity.x = dir * SPEED
	if sprite.animation != "run": sprite.play("run")
	
	# Jump Logic
	ground_check.target_position = Vector2(20.0 * dir, 30.0)
	wall_check.target_position = Vector2(20.0 * dir, 0.0)
	
	if is_on_floor() and not jump_cooldown:
		if not ground_check.is_colliding() or wall_check.is_colliding():
			_do_jump(dir)

func _chase_state():
	if target_enemy == null or not is_instance_valid(target_enemy):
		target_enemy = null
		if player:
			state = State.FOLLOW
		else:
			state = State.IDLE
		return
	
	var dx: float = target_enemy.global_position.x - global_position.x
	var dist_x: float = abs(dx)
	var dir: float = sign(dx)
	
	sprite.flip_h = dir < 0
	
	# Attack range mein aa gaya
	if dist_x <= ATTACK_RANGE:
		_start_attack()
		return
	
	velocity.x = dir * SPEED
	if sprite.animation != "run": sprite.play("run")
	
	# Jump Logic
	ground_check.target_position = Vector2(20.0 * dir, 30.0)
	wall_check.target_position = Vector2(20.0 * dir, 0.0)
	
	if is_on_floor() and not jump_cooldown:
		if not ground_check.is_colliding() or wall_check.is_colliding():
			_do_jump(dir)

# -----------------------
# ATTACK LOGIC
# -----------------------
func _start_attack():
	state = State.ATTACK
	velocity.x = 0
	sprite.play("attack")
	attack_area.monitoring = true
	
	if DEBUG_AI: print("[SHADOW] Attack Start on: ", target_enemy.name if target_enemy else "null")
	
	await sprite.animation_finished
	
	if state == State.ATTACK:
		_end_attack()

func _attack_state():
	velocity.x = 0
	
	if sprite.is_playing() and attack_area.monitoring:
		var bodies = attack_area.get_overlapping_bodies()
		for body in bodies:
			if body == target_enemy and body.has_method("take_damage"):
				if DEBUG_AI: print("[SHADOW] Dealt ", ATTACK_DAMAGE, " damage to ", body.name)
				body.take_damage(ATTACK_DAMAGE)
				attack_area.monitoring = false
				break

func _end_attack():
	attack_area.monitoring = false
	recovery_timer = ATTACK_COOLDOWN
	state = State.ATTACK_RECOVERY
	if DEBUG_AI: print("[SHADOW] Recovery Start")

func _attack_recovery_state(delta: float):
	velocity.x = 0
	sprite.play("idle")
	
	recovery_timer -= delta
	
	if recovery_timer <= 0:
		# Recovery khatam, priority check karo
		if target_enemy != null and is_instance_valid(target_enemy):
			var dist = abs(target_enemy.global_position.x - global_position.x)
			if dist <= ATTACK_RANGE:
				_start_attack()  # Same enemy pe dobara attack
			else:
				state = State.CHASE
		elif detected_enemies.size() > 0:
			# Current target khatam but list mein aur enemies hain
			state = State.CHASE  # Priority system next enemy choose karega
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
		
		# Agar yeh current target tha
		if body == target_enemy:
			target_enemy = null
			# Priority system next frame decide karega kya karna hai
	
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
	
	health_bar.value = health
	health_bar.visible = true
	
	if DEBUG_AI: print("[SHADOW] Took ", amount, " damage. Health: ", health)
	
	if health <= 0:
		die()

func die():
	state = State.DEAD
	velocity = Vector2.ZERO
	health_bar.visible = false
	
	$CollisionShape2D.set_deferred("disabled", true)
	attack_area.set_deferred("monitoring", false)
	
	emit_signal("died")
	
	if DEBUG_AI: print("[SHADOW] Died")
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await get_tree().create_timer(DEATH_ANIMATION_TIME).timeout
	else:
		await get_tree().create_timer(DEATH_ANIMATION_TIME).timeout
	
	queue_free()
