extends ProgressBar

@onready var damage_bar: ProgressBar = $Damage_bar
@onready var timer: Timer = $Timer

var mana := 0
var DEBUG := false

func _ready() -> void:
	timer.one_shot = true
	

	if DEBUG:
		print("[ManaBar] Ready")

# 🔥 CALL ONCE
func init_mana(max_mp: int) -> void:
	mana = max_mp
	max_value = max_mp
	value = max_mp

	damage_bar.max_value = max_mp
	damage_bar.value = max_mp

	if DEBUG:
		print("[ManaBar] Init:", max_mp)

# 🔥 CALL ON EVERY MANA CHANGE
func set_mana(new_mana: int) -> void:
	new_mana = clamp(new_mana, 0, max_value)
	var prev_mana := mana
	mana = new_mana

	# 🔵 Blue bar instant
	value = mana

	if mana < prev_mana:
		# SPEND → delay white bar
		timer.start()
		if DEBUG:
			print("[ManaBar] Mana spent → delay white bar")
	else:
		# REGEN → snap white bar
		damage_bar.value = mana
		timer.stop()
		if DEBUG:
			print("[ManaBar] Mana regen → snap white bar")

# 🔥 SPEND STOPPED → SNAP WHITE BAR
func _on_timer_timeout() -> void:
	damage_bar.value = mana
	if DEBUG:
		print("[ManaBar] Mana spend stopped → white bar snapped")
