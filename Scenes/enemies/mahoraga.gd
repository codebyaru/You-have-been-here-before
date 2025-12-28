extends CharacterBody2D

# -----------------------
# CONFIG & CONSTANTS
# -----------------------
const DEBUG_AI := false

const SPEED := 110.0
const JUMP_VELOCITY := -400.0
const GRAVITY := 980.0
const JUMP_COOLDOWN_TIME := 0.6
const FLOOR_SNAP_LENGTH := 10.0

const ATTACK_RANGE := 45.0
const ATTACK_DAMAGE := 100
const ATTACK_TICK_RATE := 0.7 
const ATTACK_COOLDOWN := 0.5
const ATTACK_HITBOX_FRAME := 0.3

const MAX_HEALTH := 10000
const MAX_LIVES := 30
const RESPAWN_DELAY := 2.0

# Scale Config
const BASE_SPRITE_SCALE := Vector2(0.114286, 0.169643)
const ATTACK_2_SCALE_MULT := 5.9

# --- NEW ADAPTATION CONSTANTS ---
const ADAPTATION_THRESHOLD := 5 
var adaptation_counts : Dictionary = {} 
var adapted_elements : Array = [] 

signal died
signal respawned
signal all_lives_lost

# -----------------------
# UI & COMPONENTS EXPORT
# -----------------------
@export var updates_label: Label 

# Reference to the Magic Component Node you created
@onready var magic_component = $MahoragaMagicComponent

# -----------------------
# STATE MANAGEMENT
# -----------------------
enum State { IDLE, CHASE, ATTACK, JUMPING, PACING, ATTACK_RECOVERY, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D = null
var health: int = MAX_HEALTH
var lives: int = MAX_LIVES
var spawn_position: Vector2

var jump_target_x := 0.0
var jump_forward_speed := 0.0
var jump_cooldown := false
var in_air := false
var pacing_timer := 0.0

var attack_started := false
var attack_lock := false
var attack_can_hit := false
var recovery_timer := 0.0
var damage_tick_timer := 0.0

var ground_raycasts: Array[RayCast2D] = []
var wall_raycasts: Array[RayCast2D] = []
var feet_raycast: RayCast2D = null

@onready var sprite: AnimatedSprite2D = $SpriteRoot/AnimatedSprite2D
@onready var attack_area: Area2D = $attack_area
@onready var health_bar: ProgressBar = $health_bar

# -----------------------
# IDENTITY FUNCTION (TAG)
# -----------------------
func mahoraga(): 
	pass 

# -----------------------
# INITIALIZATION
# -----------------------
func _ready():
	spawn_position = global_position
	sprite.scale = BASE_SPRITE_SCALE
	sprite.play("idle")
	attack_area.monitoring = false
	
	_setup_health_bar()
	_collect_raycasts()
	
	if updates_label:
		updates_label.modulate.a = 0 
	
	if DEBUG_AI: print("[AI-INIT] 🔥 MAHORAGA ONLINE 🔥")

func _setup_health_bar():
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	health_bar.visible = false 

func _collect_raycasts():
	ground_raycasts.clear()
	wall_raycasts.clear()
	for child in get_children():
		if child is RayCast2D:
			child.enabled = true
			child.collide_with_areas = false
			child.collide_with_bodies = true
			var r_name = child.name.to_lower()
			if "feet" in r_name: feet_raycast = child
			elif "ground" in r_name: ground_raycasts.append(child)
			elif "wall" in r_name: wall_raycasts.append(child) 
	ground_raycasts.sort_custom(func(a, b): return abs(a.target_position.x) < abs(b.target_position.x))

# -----------------------
# PHYSICS LOOP
# -----------------------
func _physics_process(delta: float) -> void:
	if state == State.DEAD: return
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		in_air = true
	else:
		in_air = false
		if jump_cooldown and velocity.y >= 0: jump_cooldown = false

	match state:
		State.IDLE: _process_idle()
		State.CHASE: _handle_movement_logic(delta)
		State.PACING: _process_pacing(delta)
		State.JUMPING: _process_jumping(delta)
		State.ATTACK: _process_attack_wait(delta)
		State.ATTACK_RECOVERY: _process_recovery(delta)

	if state == State.JUMPING:
		move_and_slide()
	else:
		apply_floor_snap()
		move_and_slide()
		
	_prevent_stacking_on_player()

# -----------------------
# CORE MOVEMENT & SMART ATTACK LOGIC
# -----------------------
func _handle_movement_logic(delta: float):
	if not player:
		state = State.IDLE
		return

	# --- 1. MAGIC ATTACK LOGIC (WHILE CHASING) ---
	# Agar adapted elements hain, aur hum attack lock mein nahi hain
	if adapted_elements.size() > 0 and not attack_lock and not in_air:
		# Random Selection Logic: Frame-based random chance (approx 1-2 times per second)
		if randf() < 0.02: 
			_try_cast_magic_attack()
			return # Agar cast kiya, to movement logic skip karo is frame ke liye

	# --- 2. MOVEMENT LOGIC ---
	var dx = player.global_position.x - global_position.x
	var dir = signf(dx)
	var dist = abs(dx)

	# Melee Attack check (Range ke andar)
	if dist <= ATTACK_RANGE and not in_air and not attack_lock:
		_start_attack()
		return

	sprite.flip_h = dir < 0
	_flip_rays(dir)
	
	if is_on_floor() and not jump_cooldown:
		var wall_hit = _check_any_wall_ahead(dir)
		if wall_hit:
			var wall_x = wall_hit.get_collision_point().x
			_initiate_parabolic_jump(wall_x + (60.0 * dir))
			return
		
		if feet_raycast.is_colliding() and not _check_ground_ahead(dir):
			var landing_x = _scan_for_landing(dir)
			if landing_x != 0.0:
				_initiate_parabolic_jump(landing_x)
				return
			else:
				state = State.PACING
				pacing_timer = 2.5
				return

	velocity.x = dir * SPEED
	
	if is_on_floor():
		if sprite.animation != "run": sprite.play("run")
	else:
		if sprite.animation != "jump" and velocity.y > 100: 
			sprite.play("jump")

# -----------------------
# MAGIC EXECUTION HELPER
# -----------------------
func _try_cast_magic_attack():
	# Randomly pick an element he knows
	var random_element = adapted_elements.pick_random()
	
	# Stop movement briefly to look cool while casting
	velocity.x = 0
	sprite.play("idle") 
	
	# Component ko bolo attack karne ko
	# (Component khud cooldown check karega, agar cooldown hai to kuch nahi hoga)
	if magic_component:
		magic_component.try_cast_stolen_magic(random_element)

# -----------------------
# MELEE COMBAT LOGIC
# -----------------------
func _start_attack():
	state = State.ATTACK
	velocity.x = 0
	var use_attack_2 = randf() < 0.5
	var anim = "attack_2" if use_attack_2 else "attack"
	sprite.play(anim)
	
	if anim == "attack_2": 
		sprite.scale = BASE_SPRITE_SCALE * ATTACK_2_SCALE_MULT
	
	attack_started = true
	attack_lock = true
	
	get_tree().create_timer(ATTACK_HITBOX_FRAME).timeout.connect(func():
		if state == State.ATTACK:
			attack_can_hit = true
			attack_area.monitoring = true
			damage_tick_timer = 0.0
	)
	await sprite.animation_finished
	
	sprite.scale = BASE_SPRITE_SCALE
	attack_area.monitoring = false
	attack_can_hit = false
	
	if state != State.ATTACK: return 

	recovery_timer = ATTACK_COOLDOWN
	state = State.ATTACK_RECOVERY

func _process_attack_wait(delta: float):
	velocity.x = 0
	
	if attack_can_hit:
		damage_tick_timer -= delta
		if damage_tick_timer <= 0:
			var bodies = attack_area.get_overlapping_bodies()
			for body in bodies:
				if body.has_method("take_damage") and body == player:
					body.take_damage(ATTACK_DAMAGE)
					if DEBUG_AI: print("[AI-DMG] 🔥 Continuous Hit!")
					damage_tick_timer = ATTACK_TICK_RATE 

	if player:
		var dist = abs(player.global_position.x - global_position.x)
		if dist > ATTACK_RANGE * 1.5:
			attack_started = false
			attack_lock = false
			attack_can_hit = false
			attack_area.monitoring = false
			sprite.scale = BASE_SPRITE_SCALE
			state = State.CHASE
			sprite.play("run")

func _process_recovery(delta: float):
	velocity.x = 0
	recovery_timer -= delta
	if recovery_timer <= 0:
		attack_lock = false
		attack_started = false
		state = State.CHASE if player else State.IDLE

# -----------------------
# DAMAGE & ADAPTATION LOGIC
# -----------------------
func take_damage(amount: int, attack_type: String = "physical"):
	if state == State.DEAD: return

	var final_damage = amount

	if attack_type != "physical":
		if attack_type in adapted_elements:
			print("🛑 MAHORAGA IMMUNE TO: ", attack_type)
			_play_immune_effect()
			return 
		
		if not adaptation_counts.has(attack_type):
			adaptation_counts[attack_type] = 0
		adaptation_counts[attack_type] += 1
		
		if adaptation_counts[attack_type] >= ADAPTATION_THRESHOLD:
			_adapt_to_element(attack_type)

	else:
		if lives == 2:
			final_damage = int(amount * 0.5)
			_show_adaptation_text("ADAPTING TO PHYSICAL ATKS", Color.GRAY)
			
		elif lives == 1:
			final_damage = int(amount * 0.2)
			_show_adaptation_text("PHYSICAL ADAPTATION COMPLETE", Color.BLACK)

	health -= final_damage
	health_bar.value = health
	health_bar.visible = true 
	
	_play_hurt_effect()

	if health <= 0:
		die()

func _adapt_to_element(element: String):
	if element in adapted_elements: return
	
	adapted_elements.append(element)
	print("⚙️ WHEEL TURNS! ADAPTED TO: ", element)
	
	var msg_color = Color.WHITE
	match element:
		"fire": msg_color = Color.ORANGE
		"water": msg_color = Color.AQUA
		"wind": msg_color = Color.GREEN
		"rock": msg_color = Color.BROWN
		"shadow": msg_color = Color.PURPLE
	
	_show_adaptation_text("ADAPTED TO " + element.to_upper(), msg_color)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.0, 0.8, 1.0), 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	_trigger_repel_shockwave()

# -----------------------
# UI HELPER
# -----------------------
func _show_adaptation_text(message: String, color: Color):
	if not updates_label: return
	
	updates_label.text = "MAHORAGA: " + message
	updates_label.modulate = color
	
	var tween = create_tween()
	tween.tween_property(updates_label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(updates_label, "modulate:a", 0.0, 0.5)

# -----------------------
# HELPERS
# -----------------------
func _play_immune_effect():
	var tween = create_tween()
	sprite.modulate = Color(3.0, 3.0, 1.092, 0.655) 
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _play_hurt_effect():
	var tween = create_tween()
	sprite.modulate = Color(1, 0.3, 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func _trigger_repel_shockwave():
	if player:
		var dir = (player.global_position - global_position).normalized()
		var force = Vector2(sign(dir.x) * 800.0, -300.0)
		if player.has_method("apply_knockback"):
			player.apply_knockback(force)

func _initiate_parabolic_jump(target_x: float):
	jump_target_x = target_x
	var hang_time = (abs(JUMP_VELOCITY) / GRAVITY) * 2.0
	var distance_needed = (target_x - global_position.x) + (20.0 * signf(target_x - global_position.x))
	jump_forward_speed = distance_needed / hang_time
	velocity.y = JUMP_VELOCITY
	velocity.x = jump_forward_speed
	state = State.JUMPING
	jump_cooldown = true
	sprite.play("jump")

func _process_jumping(delta: float):
	velocity.x = jump_forward_speed
	if is_on_floor() and velocity.y >= 0:
		if feet_raycast and not feet_raycast.is_colliding():
			global_position.x += 20.0 * signf(velocity.x)
		velocity.x = 0
		state = State.CHASE
		get_tree().create_timer(JUMP_COOLDOWN_TIME).timeout.connect(func(): jump_cooldown = false)

func _process_pacing(delta: float):
	pacing_timer -= delta
	var retreat_dir = -signf(player.global_position.x - global_position.x) if player else 1.0
	velocity.x = retreat_dir * (SPEED * 0.5)
	sprite.play("run")
	if player:
		var current_player_dir = signf(player.global_position.x - global_position.x)
		if current_player_dir != -retreat_dir:
			state = State.CHASE
			return
	if pacing_timer <= 0: state = State.CHASE

func _prevent_stacking_on_player():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == player:
			if global_position.y < player.global_position.y - 15.0:
				var push_dir = 1.0 if global_position.x > player.global_position.x else -1.0
				velocity.x = push_dir * 200.0

func _check_any_wall_ahead(dir: float) -> RayCast2D:
	for ray in wall_raycasts:
		ray.target_position.x = abs(ray.target_position.x) * dir
		ray.force_raycast_update()
		if ray.is_colliding(): return ray
	return null

func _check_ground_ahead(dir: float) -> bool:
	if ground_raycasts.size() > 0:
		var ray = ground_raycasts[0]
		ray.target_position.x = abs(ray.target_position.x) * dir
		ray.force_raycast_update()
		return ray.is_colliding()
	return true

func _scan_for_landing(dir: float) -> float:
	for i in range(1, ground_raycasts.size()):
		var ray = ground_raycasts[i]
		ray.target_position.x = abs(ray.target_position.x) * dir
		ray.force_raycast_update()
		if ray.is_colliding(): return ray.get_collision_point().x
	return 0.0

func _flip_rays(dir: float):
	for ray in ground_raycasts: ray.target_position.x = abs(ray.target_position.x) * dir
	for ray in wall_raycasts: ray.target_position.x = abs(ray.target_position.x) * dir

func die():
	state = State.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	health_bar.visible = false 
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		sprite.hide()
	emit_signal("died")
	lives -= 1
	if lives > 0:
		await get_tree().create_timer(RESPAWN_DELAY).timeout
		respawn_with_fresh_instance()
	else:
		emit_signal("all_lives_lost")
		queue_free()

func respawn_with_fresh_instance():
	var parent_node = get_parent()
	var enemy_scene = load(scene_file_path)
	if parent_node and enemy_scene:
		var new_enemy = enemy_scene.instantiate()
		new_enemy.lives = lives
		new_enemy.spawn_position = spawn_position
		new_enemy.global_position = spawn_position
		parent_node.add_child(new_enemy)
		queue_free()

func _process_idle():
	velocity.x = move_toward(velocity.x, 0, SPEED)
	sprite.play("idle")
	if player: state = State.CHASE

func _on_detection_body_entered(body):
	if body.has_method("player"): player = body
func _on_detection_body_exited(body):
	if body == player: player = null
func _on_attack_area_body_entered(body): pass
func enemy(): pass
