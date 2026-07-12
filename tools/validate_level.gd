extends SceneTree

const LEVEL_PATHS := [
	"res://data/level_01.json",
	"res://data/level_02.json",
	"res://data/level_03.json",
	"res://data/level_04.json",
	"res://data/level_05.json",
]
const MIN_OBSTACLE_SPACING := 180.0
const MIN_RANDOM_OBSTACLE_SPACING := 430.0
const MIN_RANDOM_POWERUP_SPACING := 720.0
const MAX_OBSTACLE_KIND := 9
const MAX_POWERUP_KIND := 4

func _initialize() -> void:
	var errors: Array[String] = []
	for level_path in LEVEL_PATHS:
		var level := _load_level(level_path, errors)
		if errors.is_empty():
			_validate_level(level_path, level, errors)

	if errors.is_empty():
		print("Level validation OK: ", ", ".join(LEVEL_PATHS))
		quit()
		return

	for error in errors:
		push_error(error)
	quit(1)

func _load_level(level_path: String, errors: Array[String]) -> Dictionary:
	if not FileAccess.file_exists(level_path):
		errors.append("Missing level file: " + level_path)
		return {}
	var text := FileAccess.get_file_as_string(level_path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		errors.append("Level JSON must be an object: " + level_path)
		return {}
	return parsed

func _validate_level(level_path: String, level: Dictionary, errors: Array[String]) -> void:
	var length := float(level.get("length", 0.0))
	if length < 1000.0:
		errors.append(level_path + ": Level length is too short.")

	var previous_x := -INF
	for raw_obstacle in level.get("obstacles", []):
		var obstacle: Dictionary = raw_obstacle
		var x := float(obstacle.get("x", -1.0))
		var kind := int(obstacle.get("kind", -1))
		if x <= 0.0 or x >= length:
			errors.append(level_path + ": Obstacle x out of range: " + str(obstacle))
		if kind < 0 or kind > MAX_OBSTACLE_KIND:
			errors.append(level_path + ": Obstacle kind out of range: " + str(obstacle))
		if previous_x > -INF and x - previous_x < MIN_OBSTACLE_SPACING:
			errors.append(level_path + ": Obstacle spacing too tight near x=" + str(x))
		previous_x = x

	for raw_powerup in level.get("powerups", []):
		var powerup: Dictionary = raw_powerup
		var x := float(powerup.get("x", -1.0))
		var kind := int(powerup.get("kind", -1))
		if x <= 0.0 or x >= length:
			errors.append(level_path + ": Powerup x out of range: " + str(powerup))
		if kind < 0 or kind > MAX_POWERUP_KIND:
			errors.append(level_path + ": Powerup kind out of range: " + str(powerup))

	var stars: Dictionary = level.get("stars", {})
	var count := int(stars.get("count", 0))
	if count <= 0:
		errors.append(level_path + ": Star count must be positive.")

	var layout: Dictionary = level.get("random_layout", {})
	if not layout.is_empty():
		_validate_random_layout(level_path, length, layout, errors)

func _validate_random_layout(level_path: String, length: float, layout: Dictionary, errors: Array[String]) -> void:
	var obstacle_count := int(layout.get("obstacle_count", 0))
	var obstacle_min_gap := float(layout.get("obstacle_min_gap", 0.0))
	var obstacle_max_gap := float(layout.get("obstacle_max_gap", 0.0))
	var obstacle_start_x := float(layout.get("obstacle_start_x", 0.0))
	var powerup_count := int(layout.get("powerup_count", 0))
	var powerup_min_gap := float(layout.get("powerup_min_gap", 0.0))
	var powerup_max_gap := float(layout.get("powerup_max_gap", 0.0))
	var powerup_start_x := float(layout.get("powerup_start_x", 0.0))
	var finish_margin := float(layout.get("finish_margin", 0.0))
	var end_x := length - finish_margin
	if obstacle_count <= 0:
		errors.append(level_path + ": Random obstacle count must be positive.")
	if obstacle_start_x < 600.0:
		errors.append(level_path + ": Random obstacles start too early.")
	if obstacle_min_gap < MIN_RANDOM_OBSTACLE_SPACING:
		errors.append(level_path + ": Random obstacle min gap is too low.")
	if obstacle_max_gap < obstacle_min_gap:
		errors.append(level_path + ": Random obstacle max gap is below min gap.")
	if obstacle_start_x + float(maxi(obstacle_count - 1, 0)) * obstacle_min_gap > end_x:
		errors.append(level_path + ": Random obstacles cannot fit inside level length.")
	if powerup_count <= 0:
		errors.append(level_path + ": Random powerup count must be positive.")
	if powerup_start_x < 800.0:
		errors.append(level_path + ": Random powerups start too early.")
	if powerup_min_gap < MIN_RANDOM_POWERUP_SPACING:
		errors.append(level_path + ": Random powerup min gap is too low.")
	if powerup_max_gap < powerup_min_gap:
		errors.append(level_path + ": Random powerup max gap is below min gap.")
	if powerup_start_x + float(maxi(powerup_count - 1, 0)) * powerup_min_gap > end_x:
		errors.append(level_path + ": Random powerups cannot fit inside level length.")
	for kind in layout.get("obstacle_kinds", []):
		if int(kind) < 0 or int(kind) > MAX_OBSTACLE_KIND:
			errors.append(level_path + ": Random obstacle kind out of range: " + str(kind))
	for kind in layout.get("powerup_kinds", []):
		if int(kind) < 0 or int(kind) > MAX_POWERUP_KIND:
			errors.append(level_path + ": Random powerup kind out of range: " + str(kind))
