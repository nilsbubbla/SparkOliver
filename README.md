# SparkOliver

Retro side-scrolling scooter runner for Android and web, built in Godot 4.7.

## Open

Open this folder in Godot 4.7. The project includes Android and Web export targets.

## Export

Install the Android export template and configure the Android SDK in Godot. Export with the `Android` preset to `builds/SparkOliver.apk`.

Use a private release keystore for production builds. Keystore credentials are intentionally not stored in the repository.

For the browser version, install the Web export template and export the `Web` preset. The output is
written to `builds/web/`. Copy the generated versioned HTML file to `index.html` when deploying.
Serve the directory over HTTP(S); opening it directly as a local file is not supported by browsers.

The production build is intended to be served from `https://www.fnirp.com/sparkoliver/play/`. It
uses the same run, score and global leaderboard endpoints as the Android build. The Web preset uses
threads, so the game path must return `Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`.

## Controls

- Tap/click the screen, or press Space/Enter, to jump.

The five files in `data/` control the level layouts.
