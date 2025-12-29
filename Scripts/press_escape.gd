extends Label

## Kitna bada hoga bounce karte waqt (1.2 matlab 20% bada)
@export var bounce_amount := Vector2(1.2, 1.2)
## Ek bounce complete hone mein kitna time lagega
@export var duration := 0.5

func _ready():
	# 1. Pivot ko center mein lana zaroori hai
	# Warna ye top-left corner se bounce karega jo ganda dikhta hai
	pivot_offset = size / 2
	
	# 2. Tween start karo (Looping mode mein)
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE) # Smooth movement ke liye
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 3. Pehle bada karo
	tween.tween_property(self, "scale", bounce_amount, duration)
	
	# 4. Fir wapis normal size pe lao
	tween.tween_property(self, "scale", Vector2.ONE, duration)

# Agar text change hone par size badalta hai, to pivot update karne
