extends Node2D

const LEVEL_WIDTH := 60
const LEVEL_HEIGHT := 30
const CAMERA_SPEED := 400.0

const TREE_COUNT := 30
const TREE_AREA_WIDTH := 20
const TREE_AREA_HEIGHT := 15

const TreeScene = preload("res://Scenes/Tree/Tree.tscn")
const WoodcutterScene = preload("res://Scenes/Woodcutter/Woodcutter.tscn")
const WoodcutterScript = preload("res://Scenes/Woodcutter/woodcutter.gd")

@onready var grass_layer: TileMapLayer = $Grass
@onready var camera: Camera2D = $Camera2D
@onready var _build_button: Button = $UI/BuildWoodcutterButton

var _tile_size: Vector2i
var _occupied_tiles: Dictionary = {}
var _building_mode := false
var _preview: Node2D = null

func _ready() -> void:
	for x in LEVEL_WIDTH:
		for y in LEVEL_HEIGHT:
			grass_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	_tile_size = grass_layer.tile_set.tile_size
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = LEVEL_WIDTH * _tile_size.x
	camera.limit_bottom = LEVEL_HEIGHT * _tile_size.y
	camera.position = get_viewport_rect().size / 2

	_spawn_trees()
	_build_button.pressed.connect(_on_build_woodcutter_pressed)

func _spawn_trees() -> void:
	var start_x := randi_range(0, LEVEL_WIDTH - TREE_AREA_WIDTH)
	var start_y := randi_range(0, LEVEL_HEIGHT - TREE_AREA_HEIGHT)

	var positions: Array[Vector2i] = []
	for x in TREE_AREA_WIDTH:
		for y in TREE_AREA_HEIGHT:
			positions.append(Vector2i(start_x + x, start_y + y))
	positions.shuffle()

	for i in min(TREE_COUNT, positions.size()):
		var tile_pos := positions[i]
		var tree := TreeScene.instantiate()
		tree.position = grass_layer.map_to_local(tile_pos) + Vector2(0, _tile_size.y / 2.0)
		add_child(tree)
		_occupied_tiles[tile_pos] = tree

func _on_build_woodcutter_pressed() -> void:
	if _building_mode:
		return
	_building_mode = true
	_preview = WoodcutterScene.instantiate()
	add_child(_preview)

func _cancel_building() -> void:
	_building_mode = false
	_preview.queue_free()
	_preview = null

func _place_woodcutter() -> void:
	var mouse_tile := _get_mouse_tile()
	if _is_footprint_blocked(mouse_tile):
		return
	var building := WoodcutterScene.instantiate()
	building.position = _footprint_position(mouse_tile)
	add_child(building)
	_cancel_building()

func _get_mouse_tile() -> Vector2i:
	return grass_layer.local_to_map(grass_layer.get_local_mouse_position())

func _footprint_position(top_left_tile: Vector2i) -> Vector2:
	var tl := grass_layer.map_to_local(top_left_tile)
	var x := tl.x + (WoodcutterScript.SIZE_X - 1) * _tile_size.x / 2.0
	var y := tl.y + (WoodcutterScript.SIZE_Y - 0.5) * _tile_size.y
	return Vector2(x, y)

func _is_footprint_blocked(top_left_tile: Vector2i) -> bool:
	for dx in WoodcutterScript.SIZE_X:
		for dy in WoodcutterScript.SIZE_Y:
			if _occupied_tiles.has(Vector2i(top_left_tile.x + dx, top_left_tile.y + dy)):
				return true
	return false

func _input(event: InputEvent) -> void:
	if not _building_mode:
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_place_woodcutter()
			MOUSE_BUTTON_RIGHT:
				_cancel_building()

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

	if _building_mode:
		_update_preview()

func _update_preview() -> void:
	var mouse_tile := _get_mouse_tile()
	_preview.position = _footprint_position(mouse_tile)
	_preview.modulate = Color(1, 0, 0, 0.7) if _is_footprint_blocked(mouse_tile) else Color(0, 1, 0, 0.7)
