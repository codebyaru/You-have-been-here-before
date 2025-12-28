extends Control

@export_file("*.tscn") var game_scene_path: String
@onready var settings_panel: Control = $settingpannel
@onready var back_button: Button     = $settingpannel/MarginContainer/TextureRect/CenterContainer/PanelContainer/settingvbox/BackButton
@onready var volume_slider: HSlider  = $settingpannel/MarginContainer/TextureRect/CenterContainer/PanelContainer/settingvbox/MasterVolume
@onready var credits_panel: Control = $creditspannel
@onready var credits_back_button: Button = $creditspannel/MarginContainer/TextureRect/CenterContainer/PanelContainer/creditsvbox/CreditsBackButton
@onready var intro_video: VideoStreamPlayer = $IntroVideo
@onready var main_menu: MarginContainer    = $MarginContainer
@onready var buttons_root: Control         = $MarginContainer/TextureRect/CenterContainer/VBoxContainer/Control
func _ready() -> void:
	# Show video first, hide menu
	main_menu.visible = false
	intro_video.visible = true
	intro_video.play()
	intro_video.finished.connect(_on_video_finished)
	credits_panel.visible = false
	credits_back_button.pressed.connect(_on_credits_back_pressed)

	# Connect buttons by code
	buttons_root.get_node("Start_game").pressed.connect(_on_start_pressed)
	buttons_root.get_node("Setting").pressed.connect(_on_settings_pressed)
	buttons_root.get_node("Credits").pressed.connect(_on_credits_pressed)
	buttons_root.get_node("Exit").pressed.connect(_on_exit_pressed)
	settings_panel.visible = false
	back_button.pressed.connect(_on_back_pressed)
	volume_slider.value_changed.connect(_on_volume_changed)


func _on_video_finished() -> void:
	intro_video.stop()
	intro_video.visible = false
	main_menu.visible = true


func _on_start_pressed() -> void:
	if game_scene_path != "":
		get_tree().change_scene_to_file(game_scene_path)

func _on_credits_pressed() -> void:
	print("Show credits here")
	main_menu.visible = false
	settings_panel.visible = false
	credits_panel.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()
func _on_settings_pressed() -> void:
	main_menu.visible = false
	settings_panel.visible = true

func _on_back_pressed() -> void:
	settings_panel.visible = false
	main_menu.visible = true
func _on_volume_changed(value: float) -> void:
	var db := linear_to_db(value)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
func _on_credits_back_pressed() -> void:
	credits_panel.visible = false
	main_menu.visible = true
