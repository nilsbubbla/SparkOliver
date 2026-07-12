extends SceneTree

const SOURCE := "res://assets/official_platformer/level/tiles.webp"
const OUT_PATH := "res://assets/official_platformer/level/ground_strip.png"
const SOURCE_RECT := Rect2i(0, 0, 128, 256)

func _initialize() -> void:
	var source := Image.new()
	var err := source.load(SOURCE)
	if err != OK:
		push_error("Could not load " + SOURCE + ": " + str(err))
		quit(1)
		return

	var strip := Image.create_empty(SOURCE_RECT.size.x, SOURCE_RECT.size.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	for y in range(SOURCE_RECT.size.y):
		for x in range(SOURCE_RECT.size.x):
			strip.set_pixel(x, y, source.get_pixel(SOURCE_RECT.position.x + x, SOURCE_RECT.position.y + y))

	var save_err := strip.save_png(OUT_PATH)
	if save_err != OK:
		push_error("Could not save " + OUT_PATH + ": " + str(save_err))
		quit(1)
		return
	print("Built official ground strip: ", OUT_PATH)
	quit()
