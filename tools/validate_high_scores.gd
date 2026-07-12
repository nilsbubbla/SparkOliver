extends SceneTree

const MainScene := preload("res://scenes/Main.tscn")

func _initialize() -> void:
	var errors: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	var test_scores: Array[Dictionary] = [
		{"name": "A", "score": 100},
		{"name": "B", "score": 500},
		{"name": "C", "score": 250},
		{"name": "D", "score": 300},
		{"name": "E", "score": 450},
		{"name": "F", "score": 200},
	]
	main.high_scores.clear()
	for entry in test_scores:
		main.high_scores.append(entry)
	main._sort_and_trim_high_scores()
	if main.high_scores.size() != 5:
		errors.append("High score list was not trimmed to five entries.")
	if int(main.high_scores[0].get("score", 0)) != 500:
		errors.append("High score list was not sorted descending.")
	if main._score_qualifies_for_high_scores(200):
		errors.append("Low score incorrectly qualified for a full top five.")
	if not main._score_qualifies_for_high_scores(451):
		errors.append("High score did not qualify for top five.")
	if main._sanitize_player_name("     ") != "Spelare":
		errors.append("Blank player name was not replaced.")
	if main._sanitize_player_name("abcdefghijklmnop").length() > main.HIGH_SCORE_NAME_MAX_LENGTH:
		errors.append("Player name was not shortened.")

	if errors.is_empty():
		print("High score validation OK")
		quit()
		return

	for error in errors:
		push_error(error)
	quit(1)
