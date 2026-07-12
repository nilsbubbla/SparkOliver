extends CanvasLayer

var score_label: Label
var distance_label: Label
var best_label: Label
var power_label: Label
var status_label: Label
var shade: ColorRect

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	shade = ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.035, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.visible = false
	root.add_child(shade)

	score_label = _make_label(Vector2(24, 18), 30, Color8(255, 240, 180))
	root.add_child(score_label)

	distance_label = _make_label(Vector2(24, 54), 20, Color8(204, 224, 232))
	root.add_child(distance_label)

	best_label = _make_label(Vector2(24, 80), 18, Color8(180, 207, 216))
	root.add_child(best_label)

	power_label = _make_label(Vector2(900, 18), 20, Color8(171, 242, 206))
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	power_label.size = Vector2(340, 120)
	root.add_child(power_label)

	status_label = _make_label(Vector2(0, 260), 52, Color8(255, 245, 214))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status_label.visible = false
	root.add_child(status_label)

func _make_label(pos: Vector2, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label

func update_run(score: int, distance: int, active_powerups: Dictionary, high_score: int) -> void:
	score_label.text = "Poäng " + str(score)
	distance_label.text = str(distance) + " m"
	best_label.text = "Bäst " + str(high_score)
	var parts: Array[String] = []
	for key in active_powerups.keys():
		var remaining := float(active_powerups[key])
		parts.append(_power_label(key) + " " + str(snapped(remaining, 0.1)))
	power_label.text = "\n".join(parts)

func show_status(text: String, overlay: bool) -> void:
	status_label.text = text
	status_label.visible = text.length() > 0
	shade.visible = overlay

func _power_label(kind: String) -> String:
	match kind:
		"shield":
			return "Sköld"
		"turbo":
			return "Turbo"
		"magnet":
			return "Magnet"
		"double_jump":
			return "Dubbel"
		"slow":
			return "Långsam"
	return kind
