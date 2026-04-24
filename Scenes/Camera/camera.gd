class_name GameCamera
extends Camera2D

signal panned

@export var camera_speed: float = 600.0

var _drag_active := false
var _drag_start := Vector2.ZERO
var _cam_drag_start := Vector2.ZERO

var _touch_active := false
var _touch_start := Vector2.ZERO
var _cam_touch_start := Vector2.ZERO

var _panned_emitted := false

var _cinematic_active := false
var _saved_position := Vector2.ZERO
var _saved_zoom := Vector2.ONE

func setup(level_pixel_size: Vector2i) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	limit_left = 0
	limit_top = 0
	limit_right = level_pixel_size.x
	limit_bottom = level_pixel_size.y
	position = get_viewport_rect().size / 2

func zoom_out_to_map(level_pixel_size: Vector2i, duration: float, on_complete: Callable = Callable()) -> void:
	_cinematic_active = true
	_saved_position = position
	_saved_zoom = zoom
	var map_center := Vector2(level_pixel_size) / 2.0
	var viewport_size := get_viewport_rect().size
	var zoom_factor := minf(viewport_size.x / float(level_pixel_size.x), viewport_size.y / float(level_pixel_size.y))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "zoom", Vector2(zoom_factor, zoom_factor), duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", map_center, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	if on_complete.is_valid():
		tween.chain().tween_callback(on_complete)

func zoom_in_from_map(duration: float, on_complete: Callable = Callable()) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "zoom", _saved_zoom, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", _saved_position, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func():
		_cinematic_active = false
		if on_complete.is_valid():
			on_complete.call()
	)

func _unhandled_input(event: InputEvent) -> void:
	if _cinematic_active:
		return
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
	if _cinematic_active:
		return
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
