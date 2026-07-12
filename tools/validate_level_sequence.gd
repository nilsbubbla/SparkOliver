extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")
const EXPECTED_BACKGROUNDS := [
	"res://assets/background/bg3.png",
	"res://assets/background/bana2.png",
	"res://assets/background/bana3.png",
	"res://assets/background/bana4.png",
	"res://assets/background/bana5.png",
]

func _initialize() -> void:
	var errors: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	main._start_game()
	await process_frame
	_assert_level(main, 0, errors)

	for expected_level in range(1, EXPECTED_BACKGROUNDS.size()):
		main._complete_level()
		await process_frame
		_assert_level(main, expected_level, errors)

	main._complete_level()
	await process_frame
	if main.state != main.GameState.WON:
		errors.append("Final level did not enter WON state.")

	if errors.is_empty():
		print("Level sequence validation OK")
		quit()
		return

	for error in errors:
		push_error(error)
	quit(1)

func _assert_level(main: Node, expected_level: int, errors: Array[String]) -> void:
	if int(main.current_level_index) != expected_level:
		errors.append("Expected level index " + str(expected_level) + ", got " + str(main.current_level_index))
	var background: Texture2D = main.level_background
	if background == null:
		errors.append("Level " + str(expected_level + 1) + " has no background.")
		return
	if background.resource_path != EXPECTED_BACKGROUNDS[expected_level]:
		errors.append("Level " + str(expected_level + 1) + " background mismatch: " + background.resource_path)
