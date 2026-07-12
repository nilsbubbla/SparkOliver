extends SceneTree

const OUT_PATH := "res://assets/official_platformer/level/obstacles_sheet.png"
const FRAME_SIZE := Vector2i(128, 128)
const MAX_CONTENT := Vector2i(112, 108)

const SOURCE_FILES: Array[String] = [
	"res://assets/official_platformer/props/rock_1.webp",
	"res://assets/official_platformer/props/bush_1.webp",
	"res://assets/official_platformer/props/fern_1.webp",
	"res://assets/official_platformer/props/tree_1.webp",
	"res://assets/official_platformer/props/grass_3.webp",
	"res://assets/official_platformer/props/ground_flowers_1.webp",
]

func _initialize() -> void:
	var atlas := Image.create_empty(FRAME_SIZE.x * SOURCE_FILES.size(), FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))

	for i in range(SOURCE_FILES.size()):
		var image := Image.new()
		var err := image.load(SOURCE_FILES[i])
		if err != OK:
			push_error("Could not load " + SOURCE_FILES[i] + ": " + str(err))
			quit(1)
			return
		var bounds := _alpha_bounds(image)
		var cropped := Image.create_empty(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
		cropped.fill(Color(0, 0, 0, 0))
		_copy_rect(image, cropped, bounds, Vector2i.ZERO)
		var fitted := _fit_image(cropped)
		var dst := Vector2i(i * FRAME_SIZE.x + int((FRAME_SIZE.x - fitted.get_width()) * 0.5), FRAME_SIZE.y - fitted.get_height() - 8)
		_copy_rect(fitted, atlas, Rect2i(Vector2i.ZERO, fitted.get_size()), dst)

	var save_err := atlas.save_png(OUT_PATH)
	if save_err != OK:
		push_error("Could not save " + OUT_PATH + ": " + str(save_err))
		quit(1)
		return
	print("Built official obstacle atlas: ", OUT_PATH)
	quit()

func _alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.03:
				continue
			min_x = min(min_x, x)
			min_y = min(min_y, y)
			max_x = max(max_x, x)
			max_y = max(max_y, y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _fit_image(image: Image) -> Image:
	var scale: float = min(float(MAX_CONTENT.x) / float(image.get_width()), float(MAX_CONTENT.y) / float(image.get_height()))
	var size := Vector2i(max(1, int(image.get_width() * scale)), max(1, int(image.get_height() * scale)))
	var fitted := image.duplicate()
	fitted.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return fitted

func _copy_rect(src: Image, dst: Image, rect: Rect2i, dst_pos: Vector2i) -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var color := src.get_pixel(rect.position.x + x, rect.position.y + y)
			if color.a <= 0.03:
				continue
			dst.set_pixel(dst_pos.x + x, dst_pos.y + y, color)
