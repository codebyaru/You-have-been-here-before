# 🔊 Audio System Setup Guide

## Step 1: Configure Godot Audio Buses

1. Open your project in Godot Editor
2. Go to the **Audio tab** (bottom panel)
3. Create these audio buses:

```
Master
├── Music (Volume: -3 dB)
├── SFX (Volume: 0 dB)
├── Voice (Volume: 5 dB)
├── Ambient (Volume: -5 dB)
└── UI (Volume: 0 dB)
```

4. Optional: Add effects to Music bus:
   - Reverb (Small Room preset)
   - Compressor (threshold: -20dB)

## Step 2: Configure Dialogic Audio Settings

1. Open **Dialogic** plugin (bottom panel)
2. Navigate to **Settings → Audio**
3. Set **Type Sound Audio Bus** to: `SFX`
4. Configure **Audio Channel Defaults**:

| Channel | Volume | Bus | Fade | Loop |
|---------|--------|-----|------|------|
| music   | -3 dB  | Music | 2.0s | ✓ |
| sfx     | 0 dB   | SFX | 0.1s | ✗ |
| voice   | 5 dB   | Voice | 0.3s | ✗ |
| ambient | -5 dB  | Ambient | 3.0s | ✓ |

5. (Optional) Configure typing sounds:
   - Enable typing sounds
   - Set sound folder to: `res://Audio/Typing/`
   - Set play frequency (e.g., every 2nd character)

## Step 3: Add Audio Files

1. Create the `Audio/` folder structure (see `Audio/README.md`)
2. Add your audio files to the appropriate folders
3. Ensure file names match those referenced in timeline files

## Step 4: Test Audio System

1. Run **Level 2** from the editor
2. Verify:
   - ✓ Music starts during dialogue
   - ✓ Sound effects play on events (ground shake, monster roar)
   - ✓ Combat music intensifies after dialogue
   - ✓ Music fades on level completion
3. Test all 10 levels for audio consistency

## Step 5: Troubleshooting

**No audio playing:**
- Check if audio files exist at specified paths
- Verify audio bus names match configuration
- Check volume levels aren't muted

**Audio too loud/quiet:**
- Adjust volume values in timeline files (0 dB = normal, -10 = quieter, +5 = louder)
- Adjust audio bus volumes in Godot Audio settings

**Music doesn't loop:**
- In Godot, select the audio file
- In Inspector, enable "Loop" under Import settings
- Click "Reimport"

**Choppy audio:**
- Ensure .wav files are used for short SFX
- Use .ogg for music and longer sounds
- Check system audio buffer settings

## Audio Event Syntax Reference

### Music
```
audio music "res://Audio/Music/file.ogg" [fade="1.5" volume="0"]
```

### Sound Effect
```
audio sfx "res://Audio/SFX/file.wav" [volume="0"]
```

### Voice Line
```
audio voice "res://Audio/Voice/character/file.ogg" [volume="5"]
```

### Stop Music
```
audio music - [fade="1.0" volume="-80"]
```

## Notes

- All audio is optional - game functions without it
- Voice acting paths are placeholders (optional feature)
- Audio files are NOT included in this PR (add your own)
- See `Audio/README.md` for asset recommendations
