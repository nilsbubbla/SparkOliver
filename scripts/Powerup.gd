extends Area2D

signal powerup_collected(kind: String, powerup: Area2D)

const FRAME_SIZE := 64
const KINDS: Array[String] = ["shield", "turbo", "magnet", "double_jump", "slow"]

@onready var sprite: Sprite2D = $Sprite2D

var kind := "shield"
var _base_y := 0.0
var _time := 0.0

func _ready() -> void:
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	position.y = _base_y + sin(_time * 4.2) * 8.0
	rotation = sin(_time * 2.5) * 0.08

func setup(kind_index: int) -> void:
	kind = KINDS[kind_index % KINDS.size()]
	sprite.region_rect = Rect2((kind_index % KINDS.size()) * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		powerup_collected.emit(kind, self)
		queue_free()

