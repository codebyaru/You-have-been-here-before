class_name GrowOverTime
extends Node2D

@export var growth_curve : Curve
@export var duration : float = 1.0
@export var grow_on_ready = true

signal growing_changed(status: bool)
var time_lapsed = 0.0

# 1. Variables banao (Default values ke sath)
var damage_amount : int = 100
var target_scale : float = 1.0 

var growing = false :
	set(value):
		if(value == growing):
			return
		growing = value
		emit_signal("growing_changed", growing)

# 2. Setup Function - Ye function bahar se call hoga spawn ke waqt
func setup(p_damage: int, p_scale: float):
	print("DEBUG: Setup called! Scale received: ", p_scale) # YE LINE CHECK KARO
	damage_amount = p_damage
	target_scale = p_scale

func _ready() -> void:
	if (grow_on_ready):
		start()
	
func _process(delta: float) -> void:
	if (growing):
		time_lapsed += delta
		grow()

func start():
	time_lapsed = 0.0
	growing = true 
		
func grow():
	var progress = clampf(time_lapsed / duration, 0.0, 1.0)
	
	# 3. Scale Logic Update: Curve ki value ko Target Scale se multiply karo
	var curve_value = growth_curve.sample(progress)
	
	scale = Vector2(curve_value, curve_value) * target_scale # Yahan magic hoga

	if progress >= 1.0:
		growing = false

# 4. Damage Logic Update
func _on_hitbox_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		# Variable use karo
		body.take_damage(damage_amount)
