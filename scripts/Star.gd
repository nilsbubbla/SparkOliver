extends Area2D

signal star_collected(star: Area2D)

var magnet_target: Node2D
var magnet_speed := 720.0
var _base_y := 0.0
var _time := 0.0

func _ready() -> void:
	add_to_group("stars")
	_base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_time += delta
	rotation += delta * 2.5
	if is_instance_valid(magnet_target):
		global_position = global_position.move_toward(magnet_target.global_position + Vector2(0, -84), magnet_speed * delta)
	else:
		position.y = _base_y + sin(_time * 5.0) * 5.0

func attract_to(target: Node2D) -> void:
	magnet_target = target

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		star_collected.emit(self)
		queue_free()

