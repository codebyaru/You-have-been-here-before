extends Area2D

func _ready() -> void:
	# Hum sirf "area_entered" connect karenge kyunki humne Fireball mein Area2D lagaya hai
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# 'area' wo child node hai jo humne abhi add kiya
	# 'parent' wo main fireball node hai jisme script hai
	var parent = area.get_parent()
	
	# Check karo ki kya Parent ke paas "projectile" function hai?
	if parent.has_method("projectile"):
		print("[TARGET] HIT DETECTED!")
		
		# Boss Logic (Lvl 6) ko batao
		if get_parent().get_parent().has_method("target_hit_logic"):
			get_parent().get_parent().target_hit_logic(self)
			
		# Optional: Fireball destroy kar do
		# parent.queue_free()
