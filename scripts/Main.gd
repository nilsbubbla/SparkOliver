extends Node2D

const PlayerScene := preload("res://scenes/Player.tscn")
const ObstacleScene := preload("res://scenes/Obstacle.tscn")
const PowerupScene := preload("res://scenes/Powerup.tscn")
const StarScene := preload("res://scenes/Star.tscn")
const HUDScript := preload("res://scripts/HUD.gd")

const START_SCREEN := preload("res://nysplash.png")
const FINISH_FLAG := preload("res://assets/generated/finish_flag.png")
const JUMP_SOUND := preload("res://assets/generated/jump.wav")
const PICKUP_SOUND := preload("res://assets/generated/pickup.wav")
const HIT_SOUND := preload("res://assets/generated/hit.wav")
const POWER_SOUND := preload("res://assets/generated/power.wav")
const TITLE_MUSIC := preload("res://Musik/Titel.wav")
const GAME_MUSIC := preload("res://Musik/game.wav")

const LEVEL_DATA_PATHS := [
	"res://data/level_01.json",
	"res://data/level_02.json",
	"res://data/level_03.json",
	"res://data/level_04.json",
	"res://data/level_05.json",
]
const LEVEL_BACKGROUND_PATHS := [
	"res://assets/background/bg3.png",
	"res://assets/background/bana2.png",
	"res://assets/background/bana3.png",
	"res://assets/background/bana4.png",
	"res://assets/background/bana5.png",
]

const START_SCREEN_SIZE := Vector2(1916.0, 821.0)
const START_SCREEN_WIDE_FIT_MARGIN := 0.94
const START_BUTTON_RECT := Rect2(1058.0, 472.0, 338.0, 86.0)
const OPTIONS_BUTTON_RECT := Rect2(1058.0, 566.0, 338.0, 75.0)
const HIGH_SCORES_BUTTON_RECT := Rect2(1058.0, 646.0, 338.0, 75.0)

const BACKGROUND_VIEW_HEIGHT := 720.0
const BACKGROUND_REFERENCE_HEIGHT := 724.0
const GROUND_Y := 600.0
const DEFAULT_LEVEL_LENGTH := 7200.0
const OBSTACLE_KIND_COUNT := 10
const POWERUP_KIND_COUNT := 5
const HIGH_SCORE_LIMIT := 5
const HIGH_SCORE_NAME_MAX_LENGTH := 12
const SAFE_OBSTACLE_MIN_GAP := 430.0
const SAFE_OBSTACLE_MAX_GAP := 690.0
const POWERUP_MIN_GAP := 720.0
const POWERUP_OBSTACLE_MIN_GAP := 170.0
const HIGHSCORE_RULESET_VERSION := "1.3.0"
const GLOBAL_RUN_URL := "https://www.fnirp.com/sparkoliver/api/v1/runs"
const GLOBAL_SCORE_URL := "https://www.fnirp.com/sparkoliver/api/v1/scores"
const GLOBAL_HIGH_SCORES_URL := "https://www.fnirp.com/sparkoliver/highscores.json"
const GLOBAL_HIGH_SCORES_FALLBACK_URL := "https://fnirp.com/sparkoliver/highscores.json"

enum GameState { MENU, RUNNING, PAUSED, WON, GAME_OVER }

var player: CharacterBody2D
var hud: CanvasLayer
var world: Node2D
var foreground: Node2D
var start_screen: CanvasLayer
var menu_root: Control
var menu_frame: Control
var menu_dialog: Control
var name_entry_layer: CanvasLayer
var active_powerups: Dictionary = {}
var score := 0
var score_accumulator := 0.0
var high_score := 0
var high_scores: Array[Dictionary] = []
var global_high_scores: Array[Dictionary] = []
var global_high_scores_loaded := false
var leaderboard_attempt := 0
var high_score_labels: Array[Label] = []
var high_score_source_label: Label
var pending_high_score := 0
var pending_result_status := ""
var stars := 0
var state := GameState.MENU
var distance_best := 0
var level_length := DEFAULT_LEVEL_LENGTH
var level_data: Dictionary = {}
var level_background: Texture2D
var current_level_index := 0
var audio_muted := false
var music_enabled := true
var oliver_mode_enabled := false
var active_run_id := ""
var active_run_duration_ms := 0.0

var run_request: HTTPRequest
var score_request: HTTPRequest
var leaderboard_request: HTTPRequest

var audio_jump: AudioStreamPlayer
var audio_pickup: AudioStreamPlayer
var audio_hit: AudioStreamPlayer
var audio_power: AudioStreamPlayer
var title_music_player: AudioStreamPlayer
var game_music_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_high_score()
	_load_level_data()
	_build_network_requests()
	_build_music()
	_show_start_screen()

func _exit_tree() -> void:
	for audio in [audio_jump, audio_pickup, audio_hit, audio_power, title_music_player, game_music_player]:
		if is_instance_valid(audio):
			audio.stop()
			audio.stream = null

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause_game") and state == GameState.RUNNING:
		_set_paused(true)
	elif Input.is_action_just_pressed("pause_game") and state == GameState.PAUSED:
		_set_paused(false)
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if state in [GameState.GAME_OVER, GameState.WON] and name_entry_layer == null and Input.is_action_just_pressed("jump"):
		get_tree().reload_current_scene()

	if state != GameState.RUNNING:
		return

	if not oliver_mode_enabled:
		active_run_duration_ms += delta * 1000.0
	_update_powerups(delta)
	_update_magnet()
	if not oliver_mode_enabled:
		score_accumulator += delta * 12.0 * float(_score_multiplier())
		var earned := int(score_accumulator)
		if earned > 0:
			_award_points(earned)
			score_accumulator -= float(earned)
	var meters := int(max(0.0, player.global_position.x - 180.0) / 12.0)
	distance_best = max(distance_best, meters)
	if player.global_position.x >= level_length:
		_complete_level()
		return
	_update_hud()

func _input(event: InputEvent) -> void:
	if name_entry_layer != null:
		return
	if event is InputEventScreenTouch and event.pressed:
		if state == GameState.RUNNING:
			player.request_jump()
		elif state in [GameState.GAME_OVER, GameState.WON] and name_entry_layer == null:
			get_tree().reload_current_scene()

func _show_start_screen() -> void:
	state = GameState.MENU
	start_screen = CanvasLayer.new()
	start_screen.name = "StartScreen"
	start_screen.layer = 100
	add_child(start_screen)

	menu_root = Control.new()
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_screen.add_child(menu_root)

	var background := ColorRect.new()
	background.color = Color(0.0470588, 0.0627451, 0.0901961, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(background)

	menu_frame = Control.new()
	menu_root.add_child(menu_frame)

	var texture := TextureRect.new()
	texture.texture = START_SCREEN
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_SCALE
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.clip_contents = true
	menu_frame.add_child(texture)

	_add_image_button(menu_frame, START_BUTTON_RECT, _start_game)
	_add_image_button(menu_frame, OPTIONS_BUTTON_RECT, _show_options_dialog)
	_add_image_button(menu_frame, HIGH_SCORES_BUTTON_RECT, _show_high_scores_dialog)
	if not get_viewport().size_changed.is_connected(_layout_start_screen):
		get_viewport().size_changed.connect(_layout_start_screen)
	_layout_start_screen()
	_sync_music()

func _layout_start_screen() -> void:
	if menu_frame == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale: float = min(viewport_size.x / START_SCREEN_SIZE.x, viewport_size.y / START_SCREEN_SIZE.y)
	var viewport_aspect: float = viewport_size.x / viewport_size.y
	var image_aspect: float = START_SCREEN_SIZE.x / START_SCREEN_SIZE.y
	if viewport_aspect > image_aspect + 0.05:
		scale *= START_SCREEN_WIDE_FIT_MARGIN
	var fitted_size: Vector2 = START_SCREEN_SIZE * scale
	menu_frame.position = (viewport_size - fitted_size) * 0.5
	menu_frame.size = fitted_size

func _add_image_button(parent: Control, source_rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.anchor_left = source_rect.position.x / START_SCREEN_SIZE.x
	button.anchor_top = source_rect.position.y / START_SCREEN_SIZE.y
	button.anchor_right = source_rect.end.x / START_SCREEN_SIZE.x
	button.anchor_bottom = source_rect.end.y / START_SCREEN_SIZE.y
	button.offset_left = 0
	button.offset_top = 0
	button.offset_right = 0
	button.offset_bottom = 0
	button.pressed.connect(callback)
	_make_button_invisible(button)
	parent.add_child(button)
	return button

func _make_button_invisible(button: Button) -> void:
	button.flat = true
	var empty := StyleBoxEmpty.new()
	for style_name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style_name, empty)

func _start_game() -> void:
	if state != GameState.MENU:
		return
	if start_screen != null:
		start_screen.queue_free()
	start_screen = null
	menu_root = null
	menu_frame = null
	menu_dialog = null
	score = 0
	score_accumulator = 0.0
	stars = 0
	distance_best = 0
	current_level_index = 0
	active_powerups.clear()
	_begin_global_run()
	_stop_music(title_music_player)
	_play_music(game_music_player)
	_build_audio()
	hud = HUDScript.new()
	add_child(hud)
	_start_current_level()

func _clear_audio_players() -> void:
	for audio in [audio_jump, audio_pickup, audio_hit, audio_power]:
		if is_instance_valid(audio):
			audio.queue_free()
	audio_jump = null
	audio_pickup = null
	audio_hit = null
	audio_power = null

func _return_to_menu_with_high_scores() -> void:
	_clear_level()
	if is_instance_valid(hud):
		hud.queue_free()
	hud = null
	_clear_audio_players()
	active_powerups.clear()
	pending_result_status = ""
	_stop_music(game_music_player)
	_show_start_screen()
	_show_high_scores_dialog()

func _show_options_dialog() -> void:
	_clear_menu_dialog()
	menu_dialog = _make_menu_dialog("INSTÄLLNINGAR")
	var sound_button := _make_dialog_button(Vector2(70, 92), Vector2(340, 48), _sound_label())
	sound_button.pressed.connect(func() -> void:
		audio_muted = not audio_muted
		sound_button.text = _sound_label()
	)
	menu_dialog.add_child(sound_button)
	var music_button := _make_dialog_button(Vector2(70, 154), Vector2(340, 48), _music_label())
	music_button.pressed.connect(func() -> void:
		music_enabled = not music_enabled
		music_button.text = _music_label()
		_sync_music()
	)
	menu_dialog.add_child(music_button)
	var oliver_mode_button := _make_dialog_button(Vector2(70, 216), Vector2(340, 48), _oliver_mode_label())
	oliver_mode_button.pressed.connect(func() -> void:
		oliver_mode_enabled = not oliver_mode_enabled
		oliver_mode_button.text = _oliver_mode_label()
	)
	menu_dialog.add_child(oliver_mode_button)

func _show_high_scores_dialog() -> void:
	_clear_menu_dialog()
	menu_dialog = _make_menu_dialog("TOPPLISTA")
	high_score_labels.clear()
	for i in range(HIGH_SCORE_LIMIT):
		var label := Label.new()
		label.position = Vector2(58, 84 + i * 27)
		label.size = Vector2(365, 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color8(255, 239, 186))
		menu_dialog.add_child(label)
		high_score_labels.append(label)
	high_score_source_label = Label.new()
	high_score_source_label.position = Vector2(58, 228)
	high_score_source_label.size = Vector2(365, 26)
	high_score_source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	high_score_source_label.add_theme_font_size_override("font_size", 16)
	high_score_source_label.add_theme_color_override("font_color", Color8(180, 207, 216))
	menu_dialog.add_child(high_score_source_label)
	_render_high_scores()
	leaderboard_attempt = 0
	_fetch_global_high_scores()

func _make_menu_dialog(title: String) -> Control:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var dismiss_button := Button.new()
	dismiss_button.text = ""
	dismiss_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	dismiss_button.focus_mode = Control.FOCUS_NONE
	dismiss_button.pressed.connect(_clear_menu_dialog)
	_make_button_invisible(dismiss_button)
	overlay.add_child(dismiss_button)

	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.07, 0.14, 0.94)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -240
	panel.offset_top = -165
	panel.offset_right = 240
	panel.offset_bottom = 165
	overlay.add_child(panel)

	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(0, 26)
	title_label.size = Vector2(480, 50)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color8(255, 210, 77))
	panel.add_child(title_label)
	return panel

func _make_dialog_button(position: Vector2, size: Vector2, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.position = position
	button.size = size
	button.add_theme_font_size_override("font_size", 24)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

func _sound_label() -> String:
	return "LJUD: AV" if audio_muted else "LJUD: PÅ"

func _music_label() -> String:
	return "MUSIK: PÅ" if music_enabled else "MUSIK: AV"

func _oliver_mode_label() -> String:
	return "OLIVERLÄGE: PÅ" if oliver_mode_enabled else "OLIVERLÄGE: AV"

func _clear_menu_dialog() -> void:
	if menu_dialog == null:
		return
	var overlay := menu_dialog.get_parent()
	menu_dialog = null
	high_score_labels.clear()
	high_score_source_label = null
	if overlay != null:
		overlay.queue_free()

func _start_current_level() -> void:
	_clear_level()
	active_powerups.clear()
	score_accumulator = 0.0
	distance_best = 0
	_load_level_data()
	state = GameState.RUNNING
	_build_level()
	if hud != null:
		hud.show_status("", false)
		_update_hud()

func _clear_level() -> void:
	if is_instance_valid(world):
		world.queue_free()
	world = null
	foreground = null
	player = null

func _build_level() -> void:
	world = Node2D.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)

	_build_background()
	_build_ground()

	player = PlayerScene.instantiate()
	player.position = Vector2(180, GROUND_Y)
	world.add_child(player)
	player.jumped.connect(_on_player_jumped)

	foreground = Node2D.new()
	foreground.name = "Foreground"
	world.add_child(foreground)

	_spawn_obstacles()
	_spawn_stars()
	_spawn_powerups()
	_spawn_finish()

func _build_background() -> void:
	var background_layer := Node2D.new()
	background_layer.name = "TownBackground"
	background_layer.z_index = -60
	world.add_child(background_layer)
	if level_background == null:
		return

	var scale_value := BACKGROUND_VIEW_HEIGHT / BACKGROUND_REFERENCE_HEIGHT
	var top_y := BACKGROUND_VIEW_HEIGHT - float(level_background.get_height()) * scale_value
	_repeat_sprite(
		background_layer,
		level_background,
		top_y,
		Vector2(scale_value, scale_value),
		level_length + 2200.0,
		-1400.0
	)

func _build_ground() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 2
	floor_body.collision_mask = 1
	world.add_child(floor_body)

	var floor_shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(level_length + 1600.0, 96.0)
	floor_shape.shape = rect
	floor_shape.position = Vector2(level_length * 0.5, GROUND_Y + 48.0)
	floor_body.add_child(floor_shape)

func _spawn_obstacles() -> void:
	var data: Array = level_data.get("obstacles", [])
	for item in data:
		var obstacle := ObstacleScene.instantiate()
		obstacle.position = Vector2(float(item.get("x", 0.0)), GROUND_Y)
		foreground.add_child(obstacle)
		obstacle.setup(int(item.get("kind", 0)))
		obstacle.obstacle_hit.connect(_on_obstacle_hit)

func _spawn_stars() -> void:
	var star_data: Dictionary = level_data.get("stars", {})
	var count := int(star_data.get("count", 36))
	var start_x := float(star_data.get("start_x", 520.0))
	var spacing := float(star_data.get("spacing", 176.0))
	var height := float(star_data.get("height", 185.0))
	var wave_size := float(star_data.get("wave", 54.0))
	for i in range(count):
		var star := StarScene.instantiate()
		var wave := sin(float(i) * 0.75)
		star.position = Vector2(start_x + i * spacing, GROUND_Y - height + wave * wave_size)
		foreground.add_child(star)
		star.star_collected.connect(_on_star_collected)

func _spawn_powerups() -> void:
	var data: Array = level_data.get("powerups", [])
	for item in data:
		var powerup := PowerupScene.instantiate()
		powerup.position = Vector2(float(item.get("x", 0.0)), GROUND_Y - float(item.get("height", 220.0)))
		foreground.add_child(powerup)
		powerup.setup(int(item.get("kind", 0)))
		powerup.powerup_collected.connect(_on_powerup_collected)

func _spawn_finish() -> void:
	var flag := Sprite2D.new()
	flag.texture = FINISH_FLAG
	flag.scale = Vector2(2.3, 2.3)
	flag.position = Vector2(level_length + 90.0, GROUND_Y - 120.0)
	foreground.add_child(flag)

func _add_sprite(parent: Node, texture: Texture2D, top_left: Vector2, scale: Vector2, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = scale
	sprite.position = top_left + Vector2(texture.get_width() * scale.x, texture.get_height() * scale.y) * 0.5 + offset
	parent.add_child(sprite)
	return sprite

func _repeat_sprite(parent: Node, texture: Texture2D, top_y: float, scale: Vector2, until_x: float, start_x: float = 0.0) -> void:
	var step := float(texture.get_width()) * scale.x
	var count := int(ceil((until_x - start_x) / step)) + 2
	for i in range(count):
		_add_sprite(parent, texture, Vector2(start_x + float(i) * step, top_y), scale, Vector2.ZERO)

func _build_audio() -> void:
	audio_jump = _make_audio(JUMP_SOUND)
	audio_pickup = _make_audio(PICKUP_SOUND)
	audio_hit = _make_audio(HIT_SOUND)
	audio_power = _make_audio(POWER_SOUND)

func _build_music() -> void:
	title_music_player = _make_music_player(TITLE_MUSIC)
	game_music_player = _make_music_player(GAME_MUSIC)

func _make_audio(stream: AudioStream) -> AudioStreamPlayer:
	var player_node := AudioStreamPlayer.new()
	player_node.stream = stream
	add_child(player_node)
	return player_node

func _make_music_player(stream: AudioStream) -> AudioStreamPlayer:
	var player_node := AudioStreamPlayer.new()
	player_node.stream = stream
	player_node.volume_db = -7.0
	player_node.finished.connect(func() -> void:
		_restart_music(player_node)
	)
	add_child(player_node)
	return player_node

func _on_obstacle_hit(obstacle: Area2D) -> void:
	if state != GameState.RUNNING:
		return
	if oliver_mode_enabled:
		return
	if player.shield_active:
		player.set_power_state("shield", false)
		active_powerups.erase("shield")
		_refresh_player_power_states()
		_award_points(75)
		obstacle.queue_free()
		_play_sound(audio_power)
		_update_hud()
		return
	player.apply_hit_recoil()
	_play_sound(audio_hit)
	_game_over()

func _on_star_collected(_star: Area2D) -> void:
	stars += 1
	_award_points(50 * _score_multiplier())
	_play_sound(audio_pickup)
	_update_hud()

func _on_player_jumped() -> void:
	if state == GameState.RUNNING:
		_play_sound(audio_jump)

func _on_powerup_collected(kind: String, _powerup: Area2D) -> void:
	var duration := 7.5
	if kind == "shield":
		duration = 999.0
	active_powerups[kind] = duration
	player.set_power_state(kind, true)
	_refresh_player_power_states()
	_award_points(100)
	_play_sound(audio_power)
	_update_hud()

func _update_powerups(delta: float) -> void:
	var expired: Array[String] = []
	for kind in active_powerups.keys():
		if kind == "shield":
			continue
		active_powerups[kind] = float(active_powerups[kind]) - delta
		if float(active_powerups[kind]) <= 0.0:
			expired.append(kind)
	for kind in expired:
		active_powerups.erase(kind)
		player.set_power_state(kind, false)
	_refresh_player_power_states()

func _update_magnet() -> void:
	if not player.magnet_active:
		return
	for star in get_tree().get_nodes_in_group("stars"):
		if is_instance_valid(star) and star.global_position.distance_to(player.global_position) < 360.0:
			star.attract_to(player)

func _score_multiplier() -> int:
	return 2 if active_powerups.has("turbo") else 1

func _award_points(amount: int) -> void:
	if oliver_mode_enabled:
		return
	score += amount

func _play_sound(audio: AudioStreamPlayer) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if audio_muted:
		return
	if not is_instance_valid(audio):
		return
	audio.play()

func _restart_music(music_player: AudioStreamPlayer) -> void:
	if music_enabled and is_instance_valid(music_player):
		music_player.play()

func _play_music(music_player: AudioStreamPlayer) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not is_instance_valid(music_player):
		return
	if not music_enabled:
		music_player.stop()
		return
	if not music_player.playing:
		music_player.play()

func _stop_music(music_player: AudioStreamPlayer) -> void:
	if is_instance_valid(music_player):
		music_player.stop()

func _sync_music() -> void:
	if not music_enabled:
		_stop_music(title_music_player)
		_stop_music(game_music_player)
		return
	if state == GameState.RUNNING:
		_stop_music(title_music_player)
		_play_music(game_music_player)
	elif state == GameState.MENU:
		_stop_music(game_music_player)
		_play_music(title_music_player)

func _refresh_player_power_states() -> void:
	player.set_power_state("shield", active_powerups.has("shield"))
	player.set_power_state("magnet", active_powerups.has("magnet"))
	player.set_power_state("double_jump", active_powerups.has("double_jump"))
	if active_powerups.has("slow"):
		player.speed_multiplier = 0.78
	elif active_powerups.has("turbo"):
		player.speed_multiplier = 1.28
	else:
		player.speed_multiplier = 1.0

func _set_paused(value: bool) -> void:
	if value:
		state = GameState.PAUSED
		get_tree().paused = true
		hud.process_mode = Node.PROCESS_MODE_ALWAYS
		hud.show_status("Paus", true)
	else:
		get_tree().paused = false
		state = GameState.RUNNING
		hud.show_status("", false)

func _game_over() -> void:
	state = GameState.GAME_OVER
	_stop_music(game_music_player)
	player.stop_runner()
	_finish_score_run("Försök igen")

func _complete_level() -> void:
	if current_level_index < LEVEL_DATA_PATHS.size() - 1:
		_award_points(750)
		current_level_index += 1
		_start_current_level()
		return
	_win()

func _win() -> void:
	state = GameState.WON
	_stop_music(game_music_player)
	player.start_celebration()
	_award_points(1500 + stars * 20)
	_finish_score_run("Mål!")
	_update_hud()

func _update_hud() -> void:
	if hud == null:
		return
	var meters := int(max(0.0, player.global_position.x - 180.0) / 12.0) if player != null else 0
	hud.update_run(score, meters, active_powerups, _display_best_score())

func _load_high_score() -> void:
	high_scores.clear()
	high_score = 0
	var config := ConfigFile.new()
	var err := config.load("user://sparkoliver.cfg")
	if err != OK:
		return
	var saved_scores: Variant = config.get_value("score", "high_scores", [])
	if typeof(saved_scores) == TYPE_ARRAY:
		for raw_entry in saved_scores:
			if typeof(raw_entry) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = raw_entry
			high_scores.append({
				"name": _sanitize_player_name(str(entry.get("name", "Spelare"))),
				"score": int(entry.get("score", 0)),
			})
	var legacy_high_score := int(config.get_value("score", "high_score", 0))
	if high_scores.is_empty() and legacy_high_score > 0:
		high_scores.append({"name": "Spelare", "score": legacy_high_score})
	_sort_and_trim_high_scores()
	high_score = _top_high_score()

func _load_level_data() -> void:
	level_length = DEFAULT_LEVEL_LENGTH
	level_data = {}
	var level_slot: int = clampi(current_level_index, 0, LEVEL_DATA_PATHS.size() - 1)
	var level_path: String = LEVEL_DATA_PATHS[level_slot]
	if not FileAccess.file_exists(level_path):
		level_path = LEVEL_DATA_PATHS[0]
	if not FileAccess.file_exists(level_path):
		return
	var text := FileAccess.get_file_as_string(level_path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	level_data = parsed
	level_length = float(level_data.get("length", DEFAULT_LEVEL_LENGTH))
	_randomize_level_layout()
	var background_path: String = LEVEL_BACKGROUND_PATHS[level_slot]
	var background_resource: Resource = load(background_path)
	level_background = background_resource as Texture2D
	if level_background == null:
		var fallback_background_resource: Resource = load(LEVEL_BACKGROUND_PATHS[0])
		level_background = fallback_background_resource as Texture2D

func _randomize_level_layout() -> void:
	var layout: Dictionary = level_data.get("random_layout", {})
	if layout.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var obstacles := _generate_random_obstacles(rng, layout)
	level_data["obstacles"] = obstacles
	level_data["powerups"] = _generate_random_powerups(rng, layout, obstacles)

func _generate_random_obstacles(rng: RandomNumberGenerator, layout: Dictionary) -> Array[Dictionary]:
	var count := int(layout.get("obstacle_count", 14))
	var start_x := float(layout.get("obstacle_start_x", 820.0))
	var end_x := level_length - float(layout.get("finish_margin", 700.0))
	var min_gap: float = maxf(SAFE_OBSTACLE_MIN_GAP, float(layout.get("obstacle_min_gap", SAFE_OBSTACLE_MIN_GAP)))
	var max_gap: float = maxf(min_gap, float(layout.get("obstacle_max_gap", SAFE_OBSTACLE_MAX_GAP)))
	var positions := _generate_safe_x_positions(rng, count, start_x, end_x, min_gap, max_gap)
	var kinds: Array = layout.get("obstacle_kinds", [])
	var obstacles: Array[Dictionary] = []
	for x in positions:
		obstacles.append({
			"x": snapped(float(x), 1.0),
			"kind": _random_kind(rng, kinds, OBSTACLE_KIND_COUNT),
		})
	return obstacles

func _generate_random_powerups(rng: RandomNumberGenerator, layout: Dictionary, obstacles: Array[Dictionary]) -> Array[Dictionary]:
	var count := int(layout.get("powerup_count", 5))
	var start_x := float(layout.get("powerup_start_x", 1050.0))
	var end_x := level_length - float(layout.get("finish_margin", 700.0))
	var min_gap: float = maxf(POWERUP_MIN_GAP, float(layout.get("powerup_min_gap", POWERUP_MIN_GAP)))
	var positions := _generate_powerup_positions(rng, count, start_x, end_x, min_gap, obstacles)
	var kinds: Array = layout.get("powerup_kinds", [])
	var heights: Array = layout.get("powerup_heights", [])
	var powerups: Array[Dictionary] = []
	for x in positions:
		var height := rng.randf_range(205.0, 265.0)
		if not heights.is_empty():
			height = float(heights[rng.randi_range(0, heights.size() - 1)])
		powerups.append({
			"x": snapped(float(x), 1.0),
			"kind": _random_kind(rng, kinds, POWERUP_KIND_COUNT),
			"height": snapped(height, 1.0),
		})
	return powerups

func _generate_powerup_positions(
	rng: RandomNumberGenerator,
	requested_count: int,
	start_x: float,
	end_x: float,
	min_gap: float,
	obstacles: Array[Dictionary]
) -> Array[float]:
	var positions: Array[float] = []
	if requested_count <= 0 or end_x <= start_x:
		return positions
	for attempt in range(requested_count * 120):
		if positions.size() >= requested_count:
			break
		var candidate := rng.randf_range(start_x, end_x)
		if not _is_x_far_from_obstacles(candidate, obstacles, POWERUP_OBSTACLE_MIN_GAP):
			continue
		if not _is_x_far_from_positions(candidate, positions, min_gap):
			continue
		positions.append(candidate)
	if positions.size() < requested_count:
		var cursor := start_x + rng.randf_range(0.0, 180.0)
		while positions.size() < requested_count and cursor <= end_x:
			if _is_x_far_from_obstacles(cursor, obstacles, POWERUP_OBSTACLE_MIN_GAP) and _is_x_far_from_positions(cursor, positions, min_gap):
				positions.append(cursor)
			cursor += 55.0
	positions.sort()
	return positions

func _generate_safe_x_positions(
	rng: RandomNumberGenerator,
	requested_count: int,
	start_x: float,
	end_x: float,
	min_gap: float,
	max_gap: float
) -> Array[float]:
	var positions: Array[float] = []
	if requested_count <= 0 or end_x <= start_x:
		return positions
	var count := mini(requested_count, int(floor((end_x - start_x) / min_gap)) + 1)
	if count <= 0:
		return positions
	var spare_space: float = maxf(0.0, end_x - start_x - float(count - 1) * min_gap)
	var current := start_x + rng.randf_range(0.0, minf(spare_space, max_gap - min_gap))
	positions.append(current)
	for i in range(1, count):
		var remaining := count - i - 1
		var lowest := current + min_gap
		var highest_by_gap := current + max_gap
		var highest_by_space := end_x - float(remaining) * min_gap
		var highest: float = minf(highest_by_gap, highest_by_space)
		if highest < lowest:
			highest = lowest
		current = rng.randf_range(lowest, highest)
		positions.append(current)
	return positions

func _nudge_powerup_away_from_obstacles(
	rng: RandomNumberGenerator,
	x: float,
	start_x: float,
	end_x: float,
	obstacles: Array[Dictionary]
) -> float:
	var adjusted := x
	for attempt in range(8):
		if _is_x_far_from_obstacles(adjusted, obstacles, POWERUP_OBSTACLE_MIN_GAP):
			return adjusted
		var direction := -1.0 if attempt % 2 == 0 else 1.0
		adjusted = clampf(x + direction * rng.randf_range(POWERUP_OBSTACLE_MIN_GAP, POWERUP_OBSTACLE_MIN_GAP * 2.0), start_x, end_x)
	return adjusted

func _is_x_far_from_obstacles(x: float, obstacles: Array[Dictionary], min_gap: float) -> bool:
	for obstacle in obstacles:
		if abs(x - float(obstacle.get("x", 0.0))) < min_gap:
			return false
	return true

func _is_x_far_from_positions(x: float, positions: Array[float], min_gap: float) -> bool:
	for position in positions:
		if abs(x - position) < min_gap:
			return false
	return true

func _random_kind(rng: RandomNumberGenerator, kinds: Array, fallback_count: int) -> int:
	if not kinds.is_empty():
		return int(kinds[rng.randi_range(0, kinds.size() - 1)])
	return rng.randi_range(0, fallback_count - 1)

func _finish_score_run(status_text: String) -> void:
	pending_result_status = status_text
	if not oliver_mode_enabled and score > 0:
		pending_high_score = score
		_show_name_entry()
		return
	hud.show_status(status_text, true)

func _score_qualifies_for_high_scores(value: int) -> bool:
	if value <= 0:
		return false
	if high_scores.size() < HIGH_SCORE_LIMIT:
		return true
	var lowest: Dictionary = high_scores[high_scores.size() - 1]
	return value > int(lowest.get("score", 0))

func _show_name_entry() -> void:
	if name_entry_layer != null:
		return
	var is_local_record := _score_qualifies_for_high_scores(pending_high_score)
	hud.show_status("Nytt rekord!" if is_local_record else "Spara resultat", true)
	name_entry_layer = CanvasLayer.new()
	name_entry_layer.layer = 240
	add_child(name_entry_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	name_entry_layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	var panel := ColorRect.new()
	panel.color = Color(0.02, 0.07, 0.14, 0.96)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.0
	panel.offset_left = -260
	panel.offset_top = 28
	panel.offset_right = 260
	panel.offset_bottom = 256
	root.add_child(panel)

	var title := Label.new()
	title.text = "Nytt rekord!" if is_local_record else "Spara resultat"
	title.position = Vector2(0, 18)
	title.size = Vector2(520, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color8(255, 210, 77))
	panel.add_child(title)

	var score_label := Label.new()
	score_label.text = "Poäng: " + str(pending_high_score)
	score_label.position = Vector2(0, 62)
	score_label.size = Vector2(520, 34)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 24)
	score_label.add_theme_color_override("font_color", Color8(255, 239, 186))
	panel.add_child(score_label)

	var input := LineEdit.new()
	input.position = Vector2(90, 108)
	input.size = Vector2(340, 44)
	input.max_length = HIGH_SCORE_NAME_MAX_LENGTH
	input.placeholder_text = "Skriv ditt namn"
	input.text = "Spelare"
	input.select_all_on_focus = true
	input.add_theme_font_size_override("font_size", 24)
	panel.add_child(input)

	var save_button := _make_dialog_button(Vector2(145, 168), Vector2(230, 44), "SPARA")
	panel.add_child(save_button)

	save_button.pressed.connect(func() -> void:
		_submit_high_score(input.text)
	)
	input.text_submitted.connect(func(submitted_text: String) -> void:
		_submit_high_score(submitted_text)
	)
	input.grab_focus()

func _submit_high_score(raw_name: String) -> void:
	if name_entry_layer == null:
		return
	var cleaned_name := _sanitize_player_name(raw_name)
	if _score_qualifies_for_high_scores(pending_high_score):
		high_scores.append({
			"name": cleaned_name,
			"score": pending_high_score,
		})
		_sort_and_trim_high_scores()
		high_score = _top_high_score()
		_save_high_scores()
	_submit_global_score(cleaned_name, pending_high_score)
	name_entry_layer.queue_free()
	name_entry_layer = null
	pending_high_score = 0
	_return_to_menu_with_high_scores()

func _build_network_requests() -> void:
	run_request = HTTPRequest.new()
	run_request.timeout = 8.0
	run_request.use_threads = true
	run_request.request_completed.connect(_on_run_request_completed)
	add_child(run_request)

	score_request = HTTPRequest.new()
	score_request.timeout = 8.0
	score_request.use_threads = true
	score_request.request_completed.connect(_on_score_request_completed)
	add_child(score_request)

	leaderboard_request = HTTPRequest.new()
	leaderboard_request.timeout = 8.0
	leaderboard_request.use_threads = true
	leaderboard_request.request_completed.connect(_on_leaderboard_request_completed)
	add_child(leaderboard_request)

func _begin_global_run() -> void:
	active_run_id = ""
	active_run_duration_ms = 0.0
	if oliver_mode_enabled:
		return
	var error := run_request.request(
		GLOBAL_RUN_URL,
		["Content-Type: application/json", "Accept: application/json"],
		HTTPClient.METHOD_POST,
		"{}"
	)
	if error != OK:
		active_run_id = ""

func _on_run_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 201 or oliver_mode_enabled:
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	active_run_id = str((parsed as Dictionary).get("run_id", ""))

func _submit_global_score(player_name: String, submitted_score: int) -> void:
	if oliver_mode_enabled or active_run_id.is_empty():
		return
	var payload := JSON.stringify({
		"run_id": active_run_id,
		"name": player_name,
		"score": submitted_score,
		"duration_ms": int(active_run_duration_ms),
		"game_version": HIGHSCORE_RULESET_VERSION,
		"oliver_mode": false,
	})
	var error := score_request.request(
		GLOBAL_SCORE_URL,
		["Content-Type: application/json", "Accept: application/json"],
		HTTPClient.METHOD_POST,
		payload
	)
	if error == OK:
		active_run_id = ""

func _on_score_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code in [200, 201]:
		_fetch_global_high_scores()

func _fetch_global_high_scores() -> void:
	if high_score_source_label != null:
		high_score_source_label.text = "Hämtar global topplista..."
	var url := GLOBAL_HIGH_SCORES_URL if leaderboard_attempt == 0 else GLOBAL_HIGH_SCORES_FALLBACK_URL
	var error := leaderboard_request.request(url, ["Accept: application/json"])
	if error != OK and high_score_source_label != null:
		high_score_source_label.text = "Nätverksfel " + str(error)

func _on_leaderboard_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		if leaderboard_attempt == 0:
			leaderboard_attempt = 1
			_fetch_global_high_scores.call_deferred()
			return
		global_high_scores_loaded = false
		_render_high_scores()
		if high_score_source_label != null:
			high_score_source_label.text = "Serverfel " + str(result) + "/" + str(response_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		global_high_scores_loaded = false
		_render_high_scores()
		return
	var entries: Variant = (parsed as Dictionary).get("entries", [])
	if typeof(entries) != TYPE_ARRAY:
		global_high_scores_loaded = false
		_render_high_scores()
		return
	global_high_scores_loaded = true
	global_high_scores.clear()
	for raw_entry in entries:
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		global_high_scores.append({
			"name": _sanitize_player_name(str(entry.get("name", "Spelare"))),
			"score": maxi(0, int(entry.get("score", 0))),
		})
		if global_high_scores.size() >= HIGH_SCORE_LIMIT:
			break
	_render_high_scores()
	_update_hud()

func _render_high_scores() -> void:
	if high_score_labels.is_empty():
		return
	var entries := global_high_scores if global_high_scores_loaded else high_scores
	for i in range(HIGH_SCORE_LIMIT):
		if i < entries.size():
			var entry: Dictionary = entries[i]
			high_score_labels[i].text = str(i + 1) + ". " + str(entry.get("name", "Spelare")) + " - " + str(int(entry.get("score", 0)))
		else:
			high_score_labels[i].text = str(i + 1) + ". ---"
	if high_score_source_label != null:
		high_score_source_label.text = "Global topplista" if global_high_scores_loaded else "Lokal topplista – servern kunde inte nås"

func _display_best_score() -> int:
	if global_high_scores.is_empty():
		return high_score
	return maxi(high_score, int(global_high_scores[0].get("score", 0)))

func _sanitize_player_name(raw_name: String) -> String:
	var cleaned := raw_name.strip_edges()
	cleaned = cleaned.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	if cleaned.is_empty():
		cleaned = "Spelare"
	if cleaned.length() > HIGH_SCORE_NAME_MAX_LENGTH:
		cleaned = cleaned.substr(0, HIGH_SCORE_NAME_MAX_LENGTH)
	return cleaned

func _sort_and_trim_high_scores() -> void:
	high_scores.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	)
	while high_scores.size() > HIGH_SCORE_LIMIT:
		high_scores.pop_back()

func _top_high_score() -> int:
	if high_scores.is_empty():
		return 0
	return int(high_scores[0].get("score", 0))

func _save_high_scores() -> void:
	var config := ConfigFile.new()
	config.load("user://sparkoliver.cfg")
	var saved_scores: Array = []
	for entry in high_scores:
		saved_scores.append({
			"name": str(entry.get("name", "Spelare")),
			"score": int(entry.get("score", 0)),
		})
	config.set_value("score", "high_scores", saved_scores)
	config.set_value("score", "high_score", high_score)
	config.save("user://sparkoliver.cfg")
