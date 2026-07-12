# SparkOliver

Retro side-scrolling scooter runner built in Godot 4.7.

## Run

Open this folder in Godot, or run:

```powershell
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path 'C:\Users\Nils\Desktop\SparkOliver'
```

## Validation

```powershell
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path 'C:\Users\Nils\Desktop\SparkOliver' --script 'res://tools/validate_level.gd'
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path 'C:\Users\Nils\Desktop\SparkOliver' --quit-after 240
```

## Regenerate Procedural Assets

```powershell
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path 'C:\Users\Nils\Desktop\SparkOliver' --script 'res://tools/generate_assets.gd'
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path 'C:\Users\Nils\Desktop\SparkOliver' --script 'res://tools/build_player_atlas.gd'
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path 'C:\Users\Nils\Desktop\SparkOliver' --script 'res://tools/build_official_obstacles.gd'
& 'C:\Users\Nils\Desktop\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path 'C:\Users\Nils\Desktop\SparkOliver' --script 'res://tools/build_official_ground.gd'
```

## Controls

- Space / Enter: jump
- Hold jump briefly: higher jump
- Down: fast drop
- R: restart
- P / Esc: pause

## Asset Notes

The Oliver sprite is a stylized retro-game interpretation of the local reference photos in this folder. The key visual anchors are the red/black scraped helmet, blue three-wheeled scooter, dark navy shirt, burgundy pants, and blue-black shoes.

`data/level_01.json` controls the first level's length, obstacles, star pattern, and powerup placement.

Selected environment assets come from Godot's MIT-licensed 2D Platformer Demo. See `ATTRIBUTION.md`.
