extends Area2D

signal obstacle_hit(obstacle: Area2D)

const FRAME_WIDTH := 256
const FRAME_HEIGHT := 192
const OBSTACLE_COUNT := 10
const OBSTACLE_SCALE := 0.5
const POTHOLE_KIND := 7
const POTHOLE_VERTICAL_OFFSET := 16.0
const COLLISION_SIZES := [
	Vector2(74, 112),
	Vector2(138, 92),
	Vector2(142, 94),
	Vector2(172, 78),
	Vector2(156, 92),
	Vector2(90, 122),
	Vector2(150, 30),
	Vector2(136, 38),
	Vector2(54, 154),
	Vector2(48, 136),
]
const COLLISION_POSITIONS := [
	Vector2(0, -62),
	Vector2(0, -52),
	Vector2(0, -52),
	Vector2(0, -42),
	Vector2(0, -48),
	Vector2(0, -66),
	Vector2(0, -18),
	Vector2(0, -22),
	Vector2(0, -82),
	Vector2(0, -72),
]

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var kind := 0
var consumed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(kind_index: int) -> void:
	kind = kind_index % OBSTACLE_COUNT
	var vertical_offset := POTHOLE_VERTICAL_OFFSET if kind == POTHOLE_KIND else 0.0
	sprite.scale = Vector2(OBSTACLE_SCALE, OBSTACLE_SCALE)
	sprite.position = Vector2(0, -FRAME_HEIGHT * OBSTACLE_SCALE * 0.5 + vertical_offset)
	sprite.region_rect = Rect2(kind * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
	var shape := RectangleShape2D.new()
	shape.size = COLLISION_SIZES[kind] * OBSTACLE_SCALE
	collision.position = COLLISION_POSITIONS[kind] * OBSTACLE_SCALE + Vector2(0, vertical_offset)
	collision.shape = shape

func _on_body_entered(body: Node) -> void:
	if consumed:
		return
	if body is CharacterBody2D:
		consumed = true
		obstacle_hit.emit(self)
