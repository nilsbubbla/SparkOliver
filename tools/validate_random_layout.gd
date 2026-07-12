extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const ITERATIONS_PER_LEVEL := 30
const MIN_OBSTACLE_GAP := 430.0
const MIN_POWERUP_OBSTACLE_GAP := 170.0

func _initialize() -> void:
	var errors: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	for level_index in range(main.LEVEL_DATA_PATHS.size()):
		main.current_level_index = level_index
		for iteration in range(ITERATIONS_PER_LEVEL):
			main._load_level_data()
			_validate_generated_layout(main, level_index, iteration, errors)

	if errors.is_empty():
		print("Random layout validation OK")
		quit()
		return

	for error in errors:
		push_error(error)
	quit(1)

func _validate_generated_layout(main: Node, level_index: int, iteration: int, errors: Array[String]) -> void:
	var obstacles: Array = main.level_data.get("obstacles", [])
	var powerups: Array = main.level_data.get("powerups", [])
	var level_name := "Level " + str(level_index + 1) + " iteration " + str(iteration + 1)
	if obstacles.is_empty():
		errors.append(level_name + ": no generated obstacles.")
	if powerups.is_empty():
		errors.append(level_name + ": no generated powerups.")
	var previous_x := -INF
	for raw_obstacle in obstacles:
		var obstacle: Dictionary = raw_obstacle
		var x := float(obstacle.get("x", 0.0))
		if x <= 0.0 or x >= main.level_length:
			errors.append(level_name + ": obstacle out of range at x=" + str(x))
		if previous_x > -INF and x - previous_x < MIN_OBSTACLE_GAP:
			errors.append(level_name + ": obstacle gap too low near x=" + str(x))
		previous_x = x
	for raw_powerup in powerups:
		var powerup: Dictionary = raw_powerup
		var x := float(powerup.get("x", 0.0))
		if x <= 0.0 or x >= main.level_length:
			errors.append(level_name + ": powerup out of range at x=" + str(x))
		for raw_obstacle in obstacles:
			var obstacle: Dictionary = raw_obstacle
			if abs(x - float(obstacle.get("x", 0.0))) < MIN_POWERUP_OBSTACLE_GAP:
				errors.append(level_name + ": powerup too close to obstacle at x=" + str(x))

