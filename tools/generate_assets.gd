extends SceneTree

const OUT_DIR := "res://assets/generated"

var transparent := Color(0, 0, 0, 0)
var navy := Color8(16, 31, 59)
var navy_light := Color8(33, 64, 111)
var burgundy := Color8(84, 36, 66)
var skin := Color8(246, 194, 154)
var skin_shadow := Color8(214, 141, 112)
var hair := Color8(239, 196, 93)
var helmet_red := Color8(218, 48, 53)
var helmet_black := Color8(28, 27, 32)
var helmet_scratch := Color8(238, 206, 142)
var scooter_blue := Color8(58, 184, 227)
var scooter_shadow := Color8(18, 110, 157)
var wheel := Color8(18, 23, 28)
var wheel_hi := Color8(93, 199, 230)
var metal := Color8(205, 212, 218)
var asphalt := Color8(71, 77, 84)
var asphalt_dark := Color8(48, 53, 61)
var curb := Color8(187, 179, 164)
var white := Color8(244, 247, 242)
var yellow := Color8(255, 211, 74)
var orange := Color8(236, 113, 56)
var green := Color8(76, 197, 112)
var blue := Color8(70, 129, 238)
var purple := Color8(163, 103, 220)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_make_player_sheet()
	_make_obstacles()
	_make_powerups()
	_make_tiles()
	_make_backgrounds()
	_make_ui()
	_make_sounds()
	quit()

func _new_image(width: int, height: int, color: Color = transparent) -> Image:
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image

func _save(image: Image, path: String) -> void:
	var err := image.save_png(path)
	if err != OK:
		push_error("Could not save " + path + ": " + str(err))

func _rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for yy in range(max(0, y), min(image.get_height(), y + h)):
		for xx in range(max(0, x), min(image.get_width(), x + w)):
			image.set_pixel(xx, yy, color)

func _circle(image: Image, cx: int, cy: int, r: int, color: Color) -> void:
	var rr := r * r
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= rr and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _ellipse(image: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	var rxf := float(rx * rx)
	var ryf := float(ry * ry)
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			var dx := float(x - cx)
			var dy := float(y - cy)
			if dx * dx / rxf + dy * dy / ryf <= 1.0 and x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height():
				image.set_pixel(x, y, color)

func _line(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color, thickness: int = 1) -> void:
	var dx: int = abs(x1 - x0)
	var sx: int = 1 if x0 < x1 else -1
	var dy: int = -abs(y1 - y0)
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx + dy
	var x: int = x0
	var y: int = y0
	while true:
		_rect(image, x - thickness / 2, y - thickness / 2, thickness, thickness, color)
		if x == x1 and y == y1:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy

func _outline_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	_rect(image, x, y, w, 1, color)
	_rect(image, x, y + h - 1, w, 1, color)
	_rect(image, x, y, 1, h, color)
	_rect(image, x + w - 1, y, 1, h, color)

func _blit(src: Image, dst: Image, dx: int, dy: int) -> void:
	for y in range(src.get_height()):
		for x in range(src.get_width()):
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				dst.set_pixel(dx + x, dy + y, c)

func _make_player_sheet() -> void:
	var frame_w := 96
	var frame_h := 96
	var sheet := _new_image(frame_w * 8, frame_h)
	for i in range(8):
		var frame := _draw_oliver_frame(i, frame_w, frame_h)
		_blit(frame, sheet, i * frame_w, 0)
	_save(sheet, OUT_DIR + "/oliver_scooter_sheet.png")

func _draw_oliver_frame(frame: int, w: int, h: int) -> Image:
	var image := _new_image(w, h)
	var bob_values: Array[int] = [0, -1, -2, -1, 0, 1, -3, 2]
	var bob: int = bob_values[frame]
	var wheel_spin: int = frame % 4
	var jumping: bool = frame == 6
	var hurt: bool = frame == 7
	var yoff: int = -12 if jumping else bob
	var tilt: int = -3 if jumping else (3 if hurt else 0)
	var ground_y: int = 76 + yoff

	# Scooter deck and wheels. The blue three-wheeled scooter is the strongest gameplay silhouette.
	_line(image, 18, ground_y, 70, ground_y - 2, scooter_shadow, 5)
	_line(image, 20, ground_y - 2, 72, ground_y - 4, scooter_blue, 4)
	_circle(image, 20, ground_y + 4, 7, wheel_hi)
	_circle(image, 20, ground_y + 4, 5, wheel)
	_circle(image, 66, ground_y + 2, 7, wheel_hi)
	_circle(image, 66, ground_y + 2, 5, wheel)
	_circle(image, 31, ground_y + 1, 6, wheel_hi)
	_circle(image, 31, ground_y + 1, 4, wheel)
	for x in [20, 31, 66]:
		if wheel_spin % 2 == 0:
			_line(image, x - 4, ground_y + 4, x + 4, ground_y + 4, Color8(190, 196, 201), 1)
		else:
			_line(image, x, ground_y, x, ground_y + 8, Color8(190, 196, 201), 1)
	_line(image, 55 + tilt, ground_y - 5, 47 + tilt, ground_y - 46, Color8(24, 29, 34), 4)
	_line(image, 57 + tilt, ground_y - 8, 49 + tilt, ground_y - 47, metal, 2)
	_rect(image, 36 + tilt, ground_y - 50, 24, 4, Color8(18, 19, 22))
	_circle(image, 35 + tilt, ground_y - 48, 4, Color8(18, 19, 22))
	_circle(image, 61 + tilt, ground_y - 48, 4, Color8(18, 19, 22))
	_rect(image, 24, ground_y - 8, 20, 9, scooter_blue)
	_rect(image, 27, ground_y - 11, 14, 4, Color8(133, 224, 244))

	# Body.
	_ellipse(image, 48, 43 + yoff, 13, 18, navy)
	_rect(image, 39, 37 + yoff, 19, 25, navy)
	_rect(image, 43, 41 + yoff, 11, 4, navy_light)
	_rect(image, 50, 50 + yoff, 4, 9, Color8(42, 103, 197))
	_circle(image, 48, 38 + yoff, 8, skin)
	_rect(image, 43, 45 + yoff, 10, 5, skin_shadow)

	# Legs and shoes.
	var kick_values: Array[int] = [-2, 1, 4, 1, -2, -4, 3, -7]
	var kick: int = kick_values[frame]
	_line(image, 45, 59 + yoff, 39 + kick, 72 + yoff, burgundy, 6)
	_line(image, 54, 59 + yoff, 62 - kick, 73 + yoff, burgundy, 6)
	_rect(image, 33 + kick, 72 + yoff, 12, 5, Color8(18, 24, 32))
	_rect(image, 60 - kick, 72 + yoff, 12, 5, Color8(18, 24, 32))
	_rect(image, 37 + kick, 71 + yoff, 6, 2, Color8(36, 116, 215))
	_rect(image, 63 - kick, 71 + yoff, 6, 2, Color8(36, 116, 215))

	# Arms and hands on the handlebar.
	_line(image, 41, 43 + yoff, 34 + tilt, 51 + yoff, skin, 5)
	_line(image, 54, 43 + yoff, 59 + tilt, 49 + yoff, skin, 5)
	_circle(image, 34 + tilt, 51 + yoff, 3, skin)
	_circle(image, 59 + tilt, 49 + yoff, 3, skin)

	# Head, hair, helmet, and strap.
	_circle(image, 49, 25 + yoff, 12, skin)
	_rect(image, 38, 20 + yoff, 17, 7, hair)
	_rect(image, 51, 18 + yoff, 5, 7, hair)
	_ellipse(image, 50, 16 + yoff, 18, 11, helmet_red)
	_rect(image, 34, 19 + yoff, 33, 7, helmet_black)
	_rect(image, 35, 13 + yoff, 31, 5, helmet_red)
	_rect(image, 44, 9 + yoff, 18, 5, helmet_red)
	_rect(image, 37, 13 + yoff, 7, 3, Color8(58, 58, 66))
	_rect(image, 55, 12 + yoff, 6, 3, Color8(58, 58, 66))
	_line(image, 62, 23 + yoff, 58, 38 + yoff, Color8(20, 21, 25), 2)
	_line(image, 38, 23 + yoff, 43, 39 + yoff, Color8(20, 21, 25), 2)
	_rect(image, 44, 38 + yoff, 10, 3, Color8(23, 109, 67))
	_line(image, 42, 12 + yoff, 50, 10 + yoff, helmet_scratch, 1)
	_line(image, 55, 15 + yoff, 62, 13 + yoff, helmet_scratch, 1)
	_line(image, 35, 17 + yoff, 40, 16 + yoff, helmet_scratch, 1)

	# Face.
	_rect(image, 45, 25 + yoff, 2, 2, Color8(33, 45, 58))
	_rect(image, 55, 25 + yoff, 2, 2, Color8(33, 45, 58))
	if hurt:
		_line(image, 46, 31 + yoff, 55, 29 + yoff, Color8(92, 47, 57), 1)
	else:
		_rect(image, 48, 32 + yoff, 9, 1, Color8(108, 61, 65))

	# Small retro rim light.
	_rect(image, 63, 39 + yoff, 2, 16, Color8(38, 55, 92))
	_rect(image, 72, ground_y - 4, 2, 3, Color8(140, 231, 249))
	return image

func _make_obstacles() -> void:
	var sheet := _new_image(384, 64)
	var cone := _new_image(64, 64)
	_rect(cone, 23, 18, 18, 36, orange)
	_rect(cone, 18, 50, 28, 7, Color8(72, 58, 54))
	_rect(cone, 24, 28, 16, 5, white)
	_rect(cone, 21, 40, 22, 5, white)
	_blit(cone, sheet, 0, 0)

	var puddle := _new_image(64, 64)
	_ellipse(puddle, 32, 46, 24, 8, Color8(55, 145, 192))
	_ellipse(puddle, 27, 43, 12, 4, Color8(115, 217, 241))
	_rect(puddle, 20, 48, 17, 2, Color8(38, 96, 148))
	_blit(puddle, sheet, 64, 0)

	var curb_block := _new_image(64, 64)
	_rect(curb_block, 10, 38, 44, 15, curb)
	_rect(curb_block, 10, 34, 44, 5, Color8(218, 207, 188))
	_outline_rect(curb_block, 10, 34, 44, 20, Color8(121, 112, 103))
	_rect(curb_block, 25, 39, 3, 14, Color8(145, 134, 122))
	_rect(curb_block, 40, 39, 3, 14, Color8(145, 134, 122))
	_blit(curb_block, sheet, 128, 0)

	var sign := _new_image(64, 64)
	_rect(sign, 31, 26, 3, 30, Color8(120, 128, 132))
	_rect(sign, 19, 13, 28, 18, blue)
	_outline_rect(sign, 19, 13, 28, 18, white)
	_line(sign, 25, 23, 39, 23, white, 2)
	_line(sign, 34, 18, 40, 23, white, 2)
	_line(sign, 34, 28, 40, 23, white, 2)
	_blit(sign, sheet, 192, 0)

	var toy_ball := _new_image(64, 64)
	_circle(toy_ball, 32, 43, 13, Color8(240, 61, 82))
	_circle(toy_ball, 27, 39, 5, yellow)
	_line(toy_ball, 23, 45, 41, 35, white, 2)
	_line(toy_ball, 24, 35, 40, 50, Color8(74, 126, 232), 2)
	_blit(toy_ball, sheet, 256, 0)

	var skateboard := _new_image(64, 64)
	_rect(skateboard, 16, 43, 34, 7, Color8(96, 59, 42))
	_circle(skateboard, 19, 52, 4, wheel)
	_circle(skateboard, 47, 52, 4, wheel)
	_rect(skateboard, 24, 40, 18, 3, Color8(236, 196, 72))
	_blit(skateboard, sheet, 320, 0)

	_save(sheet, OUT_DIR + "/obstacles_sheet.png")

func _make_powerups() -> void:
	var sheet := _new_image(320, 64)
	var colors: Array[Color] = [green, yellow, blue, purple, Color8(86, 226, 213)]
	for i in range(5):
		var icon := _new_image(64, 64)
		var cx := 32
		var cy := 32
		var color: Color = colors[i]
		_circle(icon, cx, cy, 22, Color8(22, 28, 38))
		_circle(icon, cx, cy, 18, color)
		_circle(icon, cx - 5, cy - 6, 5, Color8(255, 255, 255, 115))
		match i:
			0:
				_ellipse(icon, 32, 30, 11, 8, helmet_red)
				_rect(icon, 22, 31, 21, 6, helmet_black)
				_line(icon, 26, 27, 38, 24, helmet_scratch, 1)
			1:
				_line(icon, 23, 43, 42, 19, white, 4)
				_line(icon, 28, 42, 47, 18, orange, 2)
			2:
				_rect(icon, 20, 23, 8, 23, white)
				_rect(icon, 36, 23, 8, 23, white)
				_rect(icon, 20, 23, 24, 8, white)
				_rect(icon, 20, 38, 24, 8, Color8(231, 74, 74))
			3:
				_rect(icon, 24, 18, 16, 25, white)
				_rect(icon, 20, 39, 24, 5, white)
				_rect(icon, 27, 21, 10, 19, purple)
			4:
				_circle(icon, 32, 32, 7, white)
				for a in range(0, 360, 45):
					var radians := deg_to_rad(float(a))
					_line(icon, 32, 32, 32 + int(cos(radians) * 16), 32 + int(sin(radians) * 16), white, 2)
		_blit(icon, sheet, i * 64, 0)
	_save(sheet, OUT_DIR + "/powerups_sheet.png")

func _make_tiles() -> void:
	var image := _new_image(256, 128)
	for y in range(64, 128):
		for x in range(256):
			var noise := int((x * 17 + y * 31) % 17)
			image.set_pixel(x, y, asphalt.lightened(float(noise) / 130.0))
	_rect(image, 0, 54, 256, 10, curb)
	_rect(image, 0, 50, 256, 5, Color8(219, 210, 195))
	for x in range(0, 256, 32):
		_rect(image, x, 55, 2, 9, Color8(143, 133, 122))
	for x in range(12, 256, 48):
		_rect(image, x, 93, 28, 3, Color8(217, 215, 196))
	_save(image, OUT_DIR + "/street_tiles.png")

func _make_backgrounds() -> void:
	var sky := _new_image(512, 256, Color8(106, 172, 222))
	for y in range(256):
		var t := float(y) / 255.0
		var col: Color = Color8(102, 174, 229).lerp(Color8(247, 184, 105), t * 0.72)
		_rect(sky, 0, y, 512, 1, col)
	_circle(sky, 92, 74, 24, Color8(255, 222, 112))
	_circle(sky, 92, 74, 18, Color8(255, 237, 159))
	_save(sky, OUT_DIR + "/sky.png")

	var far := _new_image(512, 160)
	var house_colors: Array[Color] = [Color8(127, 143, 155), Color8(153, 132, 112), Color8(113, 142, 123)]
	for i in range(9):
		var x := i * 62 - 8
		var h := 48 + int((i * 29) % 46)
		var col: Color = house_colors[i % 3]
		_rect(far, x, 126 - h, 48, h, col)
		_rect(far, x, 126 - h, 48, 5, col.lightened(0.2))
		for wx in range(x + 8, x + 42, 14):
			for wy in range(132 - h, 118, 18):
				_rect(far, wx, wy, 6, 6, Color8(255, 225, 137))
	_rect(far, 0, 126, 512, 34, Color8(76, 116, 86))
	_save(far, OUT_DIR + "/houses_far.png")

	var near := _new_image(512, 160)
	_rect(near, 0, 118, 512, 12, Color8(111, 150, 86))
	for i in range(12):
		var x := i * 48 + int((i * 19) % 10)
		_rect(near, x, 80, 12, 48, Color8(83, 64, 51))
		_circle(near, x + 6, 72, 22, Color8(54, 113, 70))
		_circle(near, x - 8, 84, 17, Color8(62, 133, 79))
		_circle(near, x + 20, 88, 18, Color8(46, 101, 67))
	_rect(near, 0, 130, 512, 30, Color8(64, 88, 69))
	_save(near, OUT_DIR + "/trees_near.png")

func _make_ui() -> void:
	var star := _new_image(64, 64)
	var pts := [Vector2i(32, 8), Vector2i(38, 25), Vector2i(56, 25), Vector2i(42, 36), Vector2i(48, 54), Vector2i(32, 43), Vector2i(16, 54), Vector2i(22, 36), Vector2i(8, 25), Vector2i(26, 25)]
	for i in range(pts.size()):
		_line(star, pts[i].x, pts[i].y, pts[(i + 1) % pts.size()].x, pts[(i + 1) % pts.size()].y, yellow, 4)
	_circle(star, 32, 32, 12, yellow)
	_circle(star, 27, 25, 4, Color8(255, 246, 177))
	_save(star, OUT_DIR + "/star.png")

	var finish := _new_image(128, 96)
	_rect(finish, 18, 10, 4, 80, Color8(42, 43, 48))
	for y in range(10, 58, 12):
		for x in range(22, 82, 12):
			var c := white if ((x + y) / 12) % 2 == 0 else Color8(27, 31, 36)
			_rect(finish, x, y, 12, 12, c)
	_save(finish, OUT_DIR + "/finish_flag.png")

func _make_sounds() -> void:
	_make_wav(OUT_DIR + "/jump.wav", 0.16, 420.0, 780.0, 0.35)
	_make_wav(OUT_DIR + "/pickup.wav", 0.18, 620.0, 1200.0, 0.28)
	_make_wav(OUT_DIR + "/hit.wav", 0.24, 180.0, 90.0, 0.4)
	_make_wav(OUT_DIR + "/power.wav", 0.32, 400.0, 980.0, 0.32)

func _make_wav(path: String, seconds: float, start_hz: float, end_hz: float, volume: float) -> void:
	var sample_rate := 22050
	var frames := int(seconds * sample_rate)
	var data := PackedByteArray()
	data.resize(44 + frames * 2)
	_write_ascii(data, 0, "RIFF")
	_write_u32(data, 4, 36 + frames * 2)
	_write_ascii(data, 8, "WAVE")
	_write_ascii(data, 12, "fmt ")
	_write_u32(data, 16, 16)
	_write_u16(data, 20, 1)
	_write_u16(data, 22, 1)
	_write_u32(data, 24, sample_rate)
	_write_u32(data, 28, sample_rate * 2)
	_write_u16(data, 32, 2)
	_write_u16(data, 34, 16)
	_write_ascii(data, 36, "data")
	_write_u32(data, 40, frames * 2)
	var phase := 0.0
	for i in range(frames):
		var t := float(i) / float(frames)
		var hz := lerpf(start_hz, end_hz, t)
		phase += TAU * hz / float(sample_rate)
		var env := sin(t * PI)
		var sample := int(sin(phase) * env * volume * 32767.0)
		_write_i16(data, 44 + i * 2, sample)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(data)

func _write_ascii(data: PackedByteArray, offset: int, text: String) -> void:
	for i in range(text.length()):
		data[offset + i] = text.unicode_at(i)

func _write_u16(data: PackedByteArray, offset: int, value: int) -> void:
	data[offset] = value & 0xff
	data[offset + 1] = (value >> 8) & 0xff

func _write_u32(data: PackedByteArray, offset: int, value: int) -> void:
	data[offset] = value & 0xff
	data[offset + 1] = (value >> 8) & 0xff
	data[offset + 2] = (value >> 16) & 0xff
	data[offset + 3] = (value >> 24) & 0xff

func _write_i16(data: PackedByteArray, offset: int, value: int) -> void:
	if value < 0:
		value = 65536 + value
	_write_u16(data, offset, value)
