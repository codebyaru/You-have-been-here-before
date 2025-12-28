class_name Projectile
extends Node2D

@export var speed = 100.0 # Thoda speed badha diya taaki visible ho
var direction = Vector2.ZERO
var source : Node
var launched = false

func _ready() -> void:
	
	# Setup check ko thoda simplify kar diya
	call_deferred("_validate_setup")

func _physics_process(delta: float) -> void:
	# Agar launch nahi hua, toh move mat karo
	if not launched:
		return
		
	position += direction * speed * delta

func launch(p_source: Node, p_direction: Vector2):
	launched = true
	source = p_source
	direction = p_direction
	
	# AGAR DIRECTION LEFT HAI, TOH SPRITE KO FLIP KARO
	# sign() function -1, 0, ya 1 return karta hai
	if p_direction.x != 0:
		scale.x = sign(p_direction.x)

func _validate_setup():
	if not launched:
		push_warning("Projectile created but launch() was not called!")

func projectile():
	pass
