extends Control

## I called this "Container" but this is actually useable in all Control node
@export var list_delay : float = 0.1
@export var template_button : Button # <-- Yahan Inspector mein apna Button drag karna

var allc = []

func _ready():
	# 1. Pehle Buttons Generate karo (Duplicate Logic)
	_generate_buttons()
	
	# 2. Ab naye bacchon (children) ko list mein daalo animation ke liye
	allc = get_children()
	
	# Template button ko list se hata do taaki wo animation mein count na ho
	if template_button and template_button in allc:
		allc.erase(template_button)
	
	draw.connect(list_appear)

func _generate_buttons():
	if template_button == null:
		return
		
	# Template ko chup chap hide kar do (Original wala nahi dikhna chahiye)
	template_button.visible = false
	
	# --- MAIN MENU LOGIC HERE ---
	if FileAccess.file_exists("user://savegame.save"):
		# 1. Duplicate
		var new_btn = template_button.duplicate()
		
		# 2. Text Change (Dynamic)
		# Tumhare Global variable se level utha liya
		new_btn.text = "Load Save"		
		# 3. Visibility & Connection
		# Note: Visible false rakha hai taaki 'list_appear' usse animate karke dikhaye
		new_btn.visible = false 
		new_btn.pressed.connect(_on_save_clicked)
		
		# 4. Add to list
		add_child(new_btn)
		
	else:
		# Agar save nahi hai, to koi button nahi banega (ya tum "No Data" bana sakte ho)
		print("No save file found for Party List")

func _on_save_clicked():
	print("Save button clicked from Juicy List!")
	Global.load_game()
	# Yahan tum scene transition bhi daal sakte ho agar chahiye

func list_appear():
	print("visible animation starting")
	
	for c in allc:
		c.visible = false
		
	if visible == false: return
	
	for i in range(allc.size()):
		allc[i].visible = true
		
		if i == 0:
			allc[i].grab_focus()
			
		await get_tree().create_timer(list_delay).timeout
