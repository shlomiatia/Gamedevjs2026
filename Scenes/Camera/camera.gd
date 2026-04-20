extends Camera2D

signal panned

@export var camera_speed: float = 400.0
@export var edge_margin: float = 40.0

var _drag_active := false
var _drag_start := Vector2.ZERO
var _cam_drag_start := Vector2.ZERO

var _touch_active := false
var _touch_start := Vector2.ZERO
var _cam_touch_start := Vector2.ZERO

var _panned_emitted := false

func setup(level_pixel_size: Vector2i) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	limit_left = 0
	limit_top = 0
	limit_right = level_pixel_size.x
	limit_bottom = level_pixel_size.y
	position = get_viewport_rect().size / 2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		_drag_active = event.pressed
		if event.pressed:
			_drag_start = event.position
			_cam_drag_start = position

	if event is InputEventMouseMotion and _drag_active:
		position = _cam_drag_start - (event.position - _drag_start)
		_clamp_position()
		_emit_panned()

	if event is InputEventScreenTouch and event.index == 0:
		_touch_active = event.pressed
		if event.pressed:
			_touch_start = event.position
			_cam_touch_start = position

	if event is InputEventScreenDrag and event.index == 0 and _touch_active:
		position = _cam_touch_start - (event.position - _touch_start)
		_clamp_position()
		_emit_panned()

func _process(delta: float) -> void:
	var direction := Vector2.ZERO

	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		direction.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		direction.x += 1

	if direction != Vector2.ZERO:
		position += direction.normalized() * camera_speed * delta
		_clamp_position()
		_emit_panned()

func _emit_panned() -> void:
	if not _panned_emitted:
		_panned_emitted = true
		panned.emit()

func _clamp_position() -> void:
	var half_vp := get_viewport_rect().size / 2
	position = position.clamp(
		Vector2(limit_left, limit_top) + half_vp,
		Vector2(limit_right, limit_bottom) - half_vp
	)
