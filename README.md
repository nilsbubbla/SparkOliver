# SparkOliver

Android-only retro side-scrolling scooter runner built in Godot 4.7.

## Open

Open this folder in Godot 4.7. The project is configured with Android as its only export target.

## Export

Install the Android export template and configure the Android SDK in Godot. Export with the `Android` preset to `builds/SparkOliver.apk`.

Use a private release keystore for production builds. Keystore credentials are intentionally not stored in the repository.

## Controls

- Space / Enter: jump
- Hold jump briefly: higher jump
- Down: fast drop
- R: restart
- P / Esc: pause

The five files in `data/` control the level layouts.
