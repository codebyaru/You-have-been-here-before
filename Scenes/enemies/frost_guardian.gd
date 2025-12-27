extends CharacterBody2D

# -----------------------
# CONFIG & CONSTANTS
# -----------------------
# 🔥 UPDATED: Speed increased from 90 to 130
const SPEED := 130.0 
const JUMP_VELOCITY := -300.0
const GRAVITY := 980.0
const JUMP_COOLDOWN_TIME := 0.6

const ATTACK_RANGE := 40.0
const ATTACK_DAMAGE := 10
const ATTACK_TICK_RATE := 0.5 
const ATTACK_COOLDOWN := 1.0

# 🔥 NEW: Knockback Strength (X force, Y force)
const KNOCKBACK_FORCE := Vector2(400.0, -250.0) 

const MAX_HEALTH = 200
var REVERSE_FLIP = false
signal died

# -----------------------
# STATE MANAGEMENT
# -----------------------
enum State { IDLE, CHASE, ATTACK, JUMPING, PACING, ATTACK_RECOVERY, DEAD }
var state: State = State.IDLE

var player: CharacterBody2D = null
var health: int = MAX_HEALTH

# Physics
var jump_forward_speed := 0.0
var jump_cooldown := false
var in_air := false
var pacing_timer := 0.0
var current_direction := 1.0

# Combat - SIMPLIFIED
var attack_lock := false
var damage_tick_timer := 0.0
var recovery_timer := 0.0

# Raycasts
var ground_raycasts: Array[RayCast2D] = []
var wall_raycasts: Array[RayCast2D] = []
var feet_raycast: RayCast2D = null

@onready var sprite: AnimatedSprite2D = $SpriteRoot/AnimatedSprite2D
@onready var attack_area: Area2D = $attack_area
@onready var health_bar: ProgressBar = $health_bar

# -----------------------
# INITIALIZATION
# -----------------------
func _ready():
	sprite.play("idle")
	attack_area.monitoring = false
	_setup_health_bar()
	_collect_raycasts()

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
	
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		in_air = true
	else:
		in_air = false
		if jump_cooldown and velocity.y >= 0: jump_cooldown = false

	# State Machine
	match state:
		State.IDLE: _process_idle()
		State.CHASE: _handle_movement_logic(delta)
		State.PACING: _process_pacing(delta)
		State.JUMPING: _process_jumping(delta)
		State.ATTACK: _process_attack(delta)
		State.ATTACK_RECOVERY: _process_recovery(delta)

	# Movement
	if state == State.JUMPING:
		move_and_slide()
	else:
		apply_floor_snap()
		move_and_slide()
		
	_prevent_stacking_on_player()

# -----------------------
# CORE MOVEMENT
# -----------------------
func _handle_movement_logic(delta: float):
	if not player:
		state = State.IDLE
		return

	var dx = player.global_position.x - global_position.x
	var dir = signf(dx)
	var dist = abs(dx)

	# Attack Trigger
	if dist <= ATTACK_RANGE and not in_air and not attack_lock:
		_start_attack()
		return

	# Update direction
	if dir != current_direction:
		current_direction = dir
		sprite.flip_h = (dir < 0) if REVERSE_FLIP else (dir > 0)
		_flip_rays(dir)
	
	# Wall & Gap Jumping
	if is_on_floor() and not jump_cooldown:
		var wall_hit = _check_any_wall_ahead(dir)
		if wall_hit:
			var wall_x = wall_hit.get_collision_point().x
			_initiate_parabolic_jump(wall_x + (60.0 * dir))
			return
		
		if feet_raycast and feet_raycast.is_colliding() and not _check_ground_ahead(dir):
			var landing_x = _scan_for_landing(dir)
			if landing_x != 0.0:
				_initiate_parabolic_jump(landing_x)
				return
			else:
				state = State.PACING
				pacing_timer = 2.0
				return

	# Run
	velocity.x = dir * SPEED
	if is_on_floor() and sprite.animation != "run": 
		sprite.play("run")

# -----------------------
# COMBAT - UPDATED WITH KNOCKBACK
# -----------------------
func _start_attack():
	state = State.ATTACK
	velocity.x = 0
	attack_lock = true
	damage_tick_timer = 0.0
	
	sprite.play("attack")
	
	# Enable hitbox immediately
	attack_area.monitoring = true
	
	# Wait for animation
	await sprite.animation_finished
	
	# Cleanup
	attack_area.monitoring = false
	recovery_timer = ATTACK_COOLDOWN
	state = State.ATTACK_RECOVERY

func _process_attack(delta: float):
	velocity.x = 0
	
	# Continuous damage on tick
	damage_tick_timer -= delta
	if damage_tick_timer <= 0:
		var bodies = attack_area.get_overlapping_bodies()
		for body in bodies:
			if body.has_method("take_damage") and body == player:
				body.take_damage(ATTACK_DAMAGE)
				
				# 🔥 ADDED KNOCKBACK HERE
				if body.has_method("apply_knockback"):
					# Calculate push direction (Away from enemy)
					var k_dir = signf(body.global_position.x - global_position.x)
					if k_dir == 0: k_dir = 1 # Prevent 0 vector
					
					var k_vector = Vector2(KNOCKBACK_FORCE.x * k_dir, KNOCKBACK_FORCE.y)
					body.apply_knockback(k_vector)

				damage_tick_timer = ATTACK_TICK_RATE
				break
	
	# Cancel if player too far
	if player:
		var dist = abs(player.global_position.x - global_position.x)
		if dist > ATTACK_RANGE * 2.0:
			attack_area.monitoring = false
			attack_lock = false
			state = State.CHASE
			sprite.play("run")

func _process_recovery(delta: float):
	velocity.x = 0
	if sprite.animation != "idle": sprite.play("idle")
	
	recovery_timer -= delta
	if recovery_timer <= 0:
		attack_lock = false
		state = State.CHASE if player else State.IDLE

# -----------------------
# DAMAGE & DEATH
# -----------------------
func take_damage(amount: int):
	if state == State.DEAD: return

	health -= amount
	health_bar.value = health
	health_bar.visible = true 
	
	# Flash red
	var tween = create_tween()
	sprite.modulate = Color(1, 0.3, 0.3)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	
	if health <= 0:
		die()

func die():
	state = State.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	health_bar.visible = false
	attack_area.monitoring = false
	
	if sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await get_tree().create_timer(0.5).timeout
	else:
		await get_tree().create_timer(0.2).timeout
	
	_spawn_dead_body()
	emit_signal("died")
	queue_free()

func _spawn_dead_body():
	var dead_body = Sprite2D.new()
	
	if sprite.sprite_frames.has_animation("death"):
		var frame_count = sprite.sprite_frames.get_frame_count("death")
		var last_frame = sprite.sprite_frames.get_frame_texture("death", frame_count - 1)
		dead_body.texture = last_frame
	else:
		dead_body.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	
	dead_body.global_position = global_position
	dead_body.scale = sprite.scale
	dead_body.flip_h = sprite.flip_h
	dead_body.modulate = Color(0.7, 0.7, 0.7)
	dead_body.z_index = -1
	
	get_parent().add_child(dead_body)
	
	var fade_tween = dead_body.create_tween()
	fade_tween.tween_property(dead_body, "modulate:a", 0.0, 3.0).set_delay(2.0)
	fade_tween.tween_callback(dead_body.queue_free)

# -----------------------
# HELPERS
# -----------------------
func _initiate_parabolic_jump(target_x: float):
	var hang_time = (abs(JUMP_VELOCITY) / GRAVITY) * 2.0
	var distance_needed = (target_x - global_position.x) + (20.0 * signf(target_x - global_position.x))
	jump_forward_speed = distance_needed / hang_time
	velocity.y = JUMP_VELOCITY
	velocity.x = jump_forward_speed
	state = State.JUMPING
	jump_cooldown = true
	
	current_direction = signf(jump_forward_speed)
	sprite.flip_h = (current_direction < 0) if REVERSE_FLIP else (current_direction > 0)
	
	if sprite.sprite_frames.has_animation("jump"):
		sprite.play("jump")
	else:
		sprite.play("run")

func _process_jumping(delta: float):
	velocity.x = jump_forward_speed
	if is_on_floor() and velocity.y >= 0:
		velocity.x = 0
		state = State.CHASE
		get_tree().create_timer(JUMP_COOLDOWN_TIME).timeout.connect(func(): 
			jump_cooldown = false
		)

func _process_pacing(delta: float):
	pacing_timer -= delta
	var retreat_dir = -signf(player.global_position.x - global_position.x) if player else 1.0
	
	if retreat_dir != current_direction:
		current_direction = retreat_dir
		sprite.flip_h = (retreat_dir < 0) if REVERSE_FLIP else (retreat_dir > 0)
		_flip_rays(retreat_dir)
	
	velocity.x = retreat_dir * (SPEED * 0.5)
	sprite.play("run")
	
	if pacing_timer <= 0: 
		state = State.CHASE

func _prevent_stacking_on_player():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == player:
			var push_dir = 1.0 if global_position.x > player.global_position.x else -1.0
			velocity.x = push_dir * 100.0

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
	for ray in ground_raycasts: 
		ray.target_position.x = abs(ray.target_position.x) * dir
	for ray in wall_raycasts: 
		ray.target_position.x = abs(ray.target_position.x) * dir

func _process_idle():
	velocity.x = move_toward(velocity.x, 0, SPEED)
	sprite.play("idle")
	if player: state = State.CHASE

func _on_detection_body_entered(body):
	if body.has_method("player"): 
		player = body
		if state == State.IDLE:
			state = State.CHASE
	
func _on_detection_body_exited(body):
	if body == player: 
		player = null
		if state != State.ATTACK and state != State.ATTACK_RECOVERY:
			state = State.IDLE

func enemy(): pass
