extends Camera2D

@export var camera_speed: float = 400.0

func setup(level_pixel_size: Vector2i) -> void:
	limit_left = 0
	limit_top = 0
	limit_right = level_pixel_size.x
	limit_bottom = level_pixel_size.y
	position = get_viewport_rect().size / 2

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	position += direction * camera_speed * delta
	var half_vp := get_viewport_rect().size / 2
	position = position.clamp(
		Vector2(limit_left, limit_top) + half_vp,
		Vector2(limit_right, limit_bottom) - half_vp
	)
