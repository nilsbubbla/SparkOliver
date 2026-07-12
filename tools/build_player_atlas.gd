extends SceneTree

const SOURCE_DIR := "res://Sprites/sprites_realistiska_transparenta"
const OUT_PATH := "res://assets/player/oliver_player_atlas.png"
const FRAME_PADDING := Vector2i(48, 42)

const FRAME_FILES: Array[String] = [
	"push_01.png",
	"push_02.png",
	"ride_01.png",
	"idle_01.png",
	"idle_02.png",
	"jump_01.png",
	"celebrate_thumbsup.png",
	"celebrate_fist.png",
]

func _initialize() -> void:
	var frames: Array[Dictionary] = []
	var max_content := Vector2i.ZERO
	for file_name in FRAME_FILES:
		var image := Image.new()
		var path := SOURCE_DIR + "/" + file_name
		var err := image.load(path)
		if err != OK:
			push_error("Could not load " + path + ": " + str(err))
			quit(1)
			return
		var bounds := _alpha_bounds(image)
		if bounds.size == Vector2i.ZERO:
			push_error("No visible pixels in " + path)
			quit(1)
			return
		frames.append({"image": image, "bounds": bounds})
		max_content.x = max(max_content.x, bounds.size.x)
		max_content.y = max(max_content.y, bounds.size.y)

	var frame_size := max_content + FRAME_PADDING * 2
	var atlas := Image.create_empty(frame_size.x * frames.size(), frame_size.y, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))

	for i in range(frames.size()):
		var frame: Dictionary = frames[i]
		var image: Image = frame["image"]
		var bounds: Rect2i = frame["bounds"]
		var dst_x := i * frame_size.x + int((frame_size.x - bounds.size.x) * 0.5)
		var dst_y := frame_size.y - FRAME_PADDING.y - bounds.size.y
		_copy_rect(image, atlas, bounds, Vector2i(dst_x, dst_y))

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/player"))
	var save_err := atlas.save_png(OUT_PATH)
	if save_err != OK:
		push_error("Could not save " + OUT_PATH + ": " + str(save_err))
		quit(1)
		return
	print("Built player atlas: ", OUT_PATH, " frame=", frame_size)
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
	if max_x < min_x or max_y < min_y:
		return Rect2i(Vector2i.ZERO, Vector2i.ZERO)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _copy_rect(src: Image, dst: Image, rect: Rect2i, dst_pos: Vector2i) -> void:
	for y in range(rect.size.y):
		for x in range(rect.size.x):
			var color := src.get_pixel(rect.position.x + x, rect.position.y + y)
			if color.a <= 0.03:
				continue
			dst.set_pixel(dst_pos.x + x, dst_pos.y + y, color)
