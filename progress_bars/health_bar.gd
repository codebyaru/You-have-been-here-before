extends ProgressBar

@onready var damage_bar: ProgressBar = $Damage_bar
@onready var timer: Timer = $Timer

var health := 0
var DEBUG := true

func _ready() -> void:
	timer.one_shot = true
	

	if DEBUG:
		print("[HealthBar] Ready")

# 🔥 CALL ONCE
func init_health(max_hp: int) -> void:
	health = max_hp
	max_value = max_hp
	value = max_hp

	damage_bar.max_value = max_hp
	damage_bar.value = max_hp

	if DEBUG:
		print("[HealthBar] Init:", max_hp)

# 🔥 CALL ON EVERY HEALTH CHANGE
func set_health(new_health: int) -> void:
	new_health = clamp(new_health, 0, max_value)
	var prev_health := health
	health = new_health

	# 🔴 Red bar always instant
	value = health

	if health < prev_health:
		# DAMAGE → delay white bar update
		timer.start()
		if DEBUG:
			print("[HealthBar] Damage taken → delay white bar")
	else:
		# HEAL → white bar snaps instantly
		damage_bar.value = health
		timer.stop()
		if DEBUG:
			print("[HealthBar] Heal → snap white bar")

# 🔥 DAMAGE STOPPED → SNAP WHITE BAR
func _on_timer_timeout() -> void:
	damage_bar.value = health
	if DEBUG:
		print("[HealthBar] Damage stopped → white bar snapped")
