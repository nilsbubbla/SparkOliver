# SparkOliver Production Plan

## Goal

Build a polished retro side-scrolling scooter runner where Oliver rides left to right, jumps over street obstacles, collects powerups, and reaches the end of short handcrafted levels.

## Technical Direction

- Engine: Godot 4.7
- Language: GDScript
- Render style: pixel-art sprites with nearest-neighbor filtering
- Initial targets: Windows and web

## Visual Direction

Oliver should read clearly at gameplay size:

- Red and black helmet with light scratch marks
- Blond hair visible under the helmet
- Dark navy shirt
- Burgundy pants
- Blue/black shoes
- Blue three-wheeled scooter with black wheels and grey handlebar

The game uses a Swedish residential-street theme: asphalt, curbs, road signs, fences, small houses, evening sky, and readable obstacle silhouettes.

## Core Loop

1. Move automatically from left to right.
2. Jump or fast-drop to avoid hazards.
3. Collect stars and powerups.
4. Maintain flow and combo.
5. Reach the finish marker.
6. Replay for score and cleaner runs.

## Powerups

- Helmet Shield: absorbs one hit.
- Turbo Spark: temporarily increases speed and score multiplier.
- Magnet: pulls nearby stars toward Oliver.
- Double Jump: enables one extra jump while active.
- Slow Street: slows hazards and camera pacing briefly.

## Milestones

1. Playable controller, camera, scrolling level, collision, restart.
2. Oliver sprite sheet, obstacle art, powerup art, parallax background.
3. Full HUD, scoring, powerup timers, game states.
4. Three handcrafted levels and difficulty ramp.
5. Sound effects, music loop, settings, menus.
6. Export presets, packaging, QA pass.

