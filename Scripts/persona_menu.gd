extends Control

# Inspector mein in dono ko drag-drop kar dena
@export var intro_video: VideoStreamPlayer
@export var ui_color_overlay: CanvasLayer 

func _ready():
	# 1. Start State: Video ON, Menu OFF
	intro_video.visible = true
	ui_color_overlay.visible = false
	
	intro_video.play()
	
	# Jab video apne aap khatam ho jaye
	intro_video.finished.connect(_show_menu)

func _process(delta):
	# Agar video chal rahi hai aur user Space/Enter dabaye -> Skip
	if intro_video.visible and Input.is_action_just_pressed("ui_accept"):
		_show_menu()

func _show_menu():
	# 2. End State: Video OFF, Menu ON
	intro_video.stop()
	intro_video.visible = false
	
	ui_color_overlay.visible = true
	


func _direct_enter_state() -> void:
	pass # Replace with function body.
