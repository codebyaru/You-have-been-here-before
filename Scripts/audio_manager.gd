extends Node

# Music player
var music_player := AudioStreamPlayer. new()

# SFX players pool (for overlapping sounds)
var sfx_players := []
const MAX_SFX_PLAYERS = 10

func _ready():
	# Add music player
	add_child(music_player)
	music_player.name = "MusicPlayer"
	
	# Create SFX player pool
	for i in range(MAX_SFX_PLAYERS):
		var player := AudioStreamPlayer.new()
		player.name = "SFXPlayer" + str(i)
		add_child(player)
		sfx_players.append(player)

# Play background music
func play_music(music_path: String, volume_db: float = -5.0):
	var music = load(music_path)
	if music:
		music_player.stream = music
		music_player.volume_db = volume_db
		
		# Enable looping for MP3
		if music is AudioStreamMP3:
			music. loop = true
		elif music is AudioStreamOggVorbis:
			music.loop = true
			
		music_player.play()
	else:
		print("Error: Could not load music at " + music_path)

# Stop music
func stop_music():
	music_player.stop()

# Play sound effect
func play_sfx(sfx_path: String, volume_db: float = 0.0):
	# Find available player
	for player in sfx_players: 
		if not player.playing:
			var sfx = load(sfx_path)
			if sfx:
				player.stream = sfx
				player.volume_db = volume_db
				player.play()
				return
			else:
				print("Error:  Could not load SFX at " + sfx_path)
				return
	
	print("Warning: All SFX players are busy")

# Fade out music (optional - for smooth transitions)
func fade_out_music(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80, duration)
	tween.tween_callback(music_player.stop) 	
