extends CharacterBody2D

signal jumped

const FRAME_WIDTH := 925
const FRAME_HEIGHT := 1191
const RUN_FRAMES: Array[int] = [0, 1, 2, 1]
const IDLE_FRAMES: Array[int] = [3, 4]
const JUMP_FRAME := 5
const HURT_FRAME := 5
const CELEBRATION_FRAMES: Array[int] = [6, 7]

@export var base_speed := 330.0
@export var gravity := 1850.0
@export var jump_velocity := -720.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shield_glow: Sprite2D = $ShieldGlow
@onready var camera: Camera2D = $Camera2D

var input_locked := false
var speed_multiplier := 1.0
var double_jump_enabled := false
var shield_active := false
var magnet_active := false
var hurt_time := 0.0
var celebrating := false

var _animation_time := 0.0
var _jump_buffer := 0.0
var _coyote_time := 0.0
var _double_jump_available := false

func _ready() -> void:
	camera.make_current()
	_set_frame(0)

func _physics_process(delta: float) -> void:
	if input_locked:
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
	else:
		velocity.x = base_speed * speed_multiplier

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		_coyote_time = 0.12
		_double_jump_available = double_jump_enabled
		if velocity.y > 0.0:
			velocity.y = 0.0

	if _coyote_time > 0.0:
		_coyote_time -= delta
	if _jump_buffer > 0.0:
		_jump_buffer -= delta
	if hurt_time > 0.0:
		hurt_time -= delta

	if not input_locked:
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = 0.14
		if _jump_buffer > 0.0:
			_try_jump()
		if Input.is_action_just_released("jump") and velocity.y < jump_velocity * 0.45:
			velocity.y = jump_velocity * 0.45
	move_and_slide()
	_update_sprite(delta)

func request_jump() -> void:
	_jump_buffer = 0.14

func _try_jump() -> void:
	if is_on_floor() or _coyote_time > 0.0:
		velocity.y = jump_velocity
		_jump_buffer = 0.0
		_coyote_time = 0.0
		jumped.emit()
	elif _double_jump_available:
		velocity.y = jump_velocity * 0.92
		_double_jump_available = false
		_jump_buffer = 0.0
		jumped.emit()

func _update_sprite(delta: float) -> void:
	if celebrating:
		_animation_time += delta * 4.5
		var celebration_index := int(_animation_time) % CELEBRATION_FRAMES.size()
		_set_frame(CELEBRATION_FRAMES[celebration_index])
	elif input_locked and is_on_floor():
		_animation_time += delta * 3.0
		var idle_index := int(_animation_time) % IDLE_FRAMES.size()
		_set_frame(IDLE_FRAMES[idle_index])
	elif hurt_time > 0.0:
		_set_frame(HURT_FRAME)
	elif not is_on_floor():
		_set_frame(JUMP_FRAME)
	else:
		_animation_time += delta * 13.0 * clamp(speed_multiplier, 0.7, 1.5)
		var frame_index := int(_animation_time) % RUN_FRAMES.size()
		_set_frame(RUN_FRAMES[frame_index])
	shield_glow.visible = shield_active

func _set_frame(frame: int) -> void:
	sprite.region_rect = Rect2(frame * FRAME_WIDTH, 0, FRAME_WIDTH, FRAME_HEIGHT)
	shield_glow.region_rect = sprite.region_rect

func apply_hit_recoil() -> void:
	hurt_time = 0.55
	velocity.y = jump_velocity * 0.45

func set_power_state(kind: String, active: bool) -> void:
	match kind:
		"shield":
			shield_active = active
		"turbo":
			pass
		"magnet":
			magnet_active = active
		"double_jump":
			double_jump_enabled = active
			_double_jump_available = active
		"slow":
			pass

func stop_runner() -> void:
	input_locked = true

func start_celebration() -> void:
	input_locked = true
	celebrating = true
	_animation_time = 0.0
