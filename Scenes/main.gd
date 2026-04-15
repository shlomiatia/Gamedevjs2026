extends Node2D

const LEVEL_WIDTH := 60
const LEVEL_HEIGHT := 30
const CAMERA_SPEED := 400.0

@onready var grass_layer: TileMapLayer = $Grass
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	for x in LEVEL_WIDTH:
		for y in LEVEL_HEIGHT:
			grass_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	var tile_size := grass_layer.tile_set.tile_size
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH * tile_size.x
	camera.limit_bottom = LEVEL_HEIGHT * tile_size.y
	camera.position = get_viewport_rect().size / 2

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
	camera.position += direction * CAMERA_SPEED * delta
	var half_vp := get_viewport_rect().size / 2
	camera.position = camera.position.clamp(
		Vector2(camera.limit_left, camera.limit_top) + half_vp,
		Vector2(camera.limit_right, camera.limit_bottom) - half_vp
	)
