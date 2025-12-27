class_name AbilitySlot
extends MarginContainer

# --- CONFIG ---
@export var icon_texture: Texture2D

# --- NODES ---
@onready var icon_rect: ColorRect = $IconRect
@onready var mana_label: Label = $ManaLabel
@onready var button: Button = $Button 

# --- SIGNALS ---
signal slot_clicked 

# --- VARS ---
var cooldown_value: float = 100.0
var is_locked: bool = false
var tween: Tween
var unlock_tween: Tween # New Tween purely for unlock effect

func _ready() -> void:
	# 1. Setup Shader
	if icon_rect.material:
		icon_rect.material = icon_rect.material.duplicate()
		if icon_texture:
			icon_rect.material.set_shader_parameter("custom_texture", icon_texture)
		# Ensure unlock effect is OFF by default
		icon_rect.material.set_shader_parameter("unlock_progress", 0.0)
	
	# 2. Setup Button Signals
	if button:
		button.pressed.connect(_on_button_pressed)
		button.mouse_entered.connect(_on_hover_enter)
		button.mouse_exited.connect(_on_hover_exit)
	
	# 3. Setup Label
	if mana_label: mana_label.visible = false
	
	# 4. Reset
	cooldown_value = 100.0
	icon_rect.modulate = Color.WHITE
	_update_shader()

func _process(_delta: float) -> void:
	_update_shader()

func _update_shader() -> void:
	if icon_rect.material:
		icon_rect.material.set_shader_parameter("cooldown_progress", int(cooldown_value))

# --- BUTTON CLICK LOGIC ---
func _on_button_pressed() -> void:
	if is_locked: return
	emit_signal("slot_clicked")

# --- HOVER LOGIC ---
func _on_hover_enter() -> void:
	if is_locked or mana_label.visible: return
	var t = create_tween()
	t.tween_property(icon_rect, "modulate", Color(0.7, 0.7, 0.7), 0.1)

func _on_hover_exit() -> void:
	if is_locked or mana_label.visible: return
	var t = create_tween()
	t.tween_property(icon_rect, "modulate", Color.WHITE, 0.1)

# --- ANIMATION LOGIC ---
func activate(time: float) -> void:
	if is_locked: return
	
	mana_label.visible = false
	icon_rect.modulate = Color.WHITE 
	
	cooldown_value = 0.0
	
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(self, "cooldown_value", 100.0, time).from(0.0)

func show_no_mana() -> void:
	cooldown_value = 0.0 
	icon_rect.modulate = Color(0.2, 0.2, 0.2) 
	
	if mana_label:
		mana_label.visible = true
		mana_label.text = "NO MANA"
	
	var t = create_tween()
	t.tween_interval(0.5)
	t.tween_callback(revert_mana_warning)

func revert_mana_warning() -> void:
	mana_label.visible = false
	if not is_locked:
		cooldown_value = 100.0
		if button and button.is_hovered():
			icon_rect.modulate = Color(0.7, 0.7, 0.7)
		else:
			icon_rect.modulate = Color.WHITE

func lock() -> void:
	is_locked = true
	cooldown_value = 0.0
	icon_rect.modulate = Color(0.2, 0.2, 0.2)
	# Reset shader shine just in case
	if icon_rect.material:
		icon_rect.material.set_shader_parameter("unlock_progress", 0.0)
		
	if button: 
		button.disabled = true
		button.mouse_default_cursor_shape = Control.CURSOR_ARROW

# --- UPDATED UNLOCK FUNCTION ---
func unlock() -> void:
	is_locked = false
	cooldown_value = 100.0
	icon_rect.modulate = Color.WHITE
	
	if button: 
		button.disabled = false
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
	# --- PLAY SHADER ANIMATION ---
	# Hum "unlock_progress" param ko 0.0 se 1.5 tak animate karenge
	if icon_rect.material:
		if unlock_tween: unlock_tween.kill()
		unlock_tween = create_tween()
		
		# 1. Start from 0
		icon_rect.material.set_shader_parameter("unlock_progress", 0.0)
		
		# 2. Animate to 1.5 over 0.8 seconds (Flash + Sweep)
		unlock_tween.tween_method(
			func(val): icon_rect.material.set_shader_parameter("unlock_progress", val),
			0.0, 
			1.5, 
			0.8
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		
		# 3. Reset back to 0 at the end
		unlock_tween.tween_callback(func(): 
			icon_rect.material.set_shader_parameter("unlock_progress", 0.0)
		)
