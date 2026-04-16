class_name BuildingManager
extends Node2D

var occupied_tiles: Dictionary = {}

const WoodcutterHutScene = preload("res://Scenes/Buildings/WoodcutterHut/WoodcutterHut.tscn")
const BuilderHutScene = preload("res://Scenes/Buildings/BuilderHut/BuilderHut.tscn")

var _grass_layer: TileMapLayer
var _spawn_parent: Node2D
var _tile_size: Vector2i
var _building_mode := false
var _preview: Node2D = null
var _active_scene: PackedScene = null
var _active_size: Vector2i = Vector2i.ZERO
var _coordination_manager: Node = null

@onready var _build_woodcutter_button: Button = $UI/BuildWoodcutterHutButton
@onready var _build_builder_button: Button = $UI/BuildBuilderHutButton

func _ready() -> void:
	_grass_layer = get_parent().get_node("Grass") as TileMapLayer
	_spawn_parent = get_parent() as Node2D
	_tile_size = _grass_layer.tile_set.tile_size
	_coordination_manager = get_parent().get_node("CoordinationManager")
	_build_woodcutter_button.pressed.connect(
		func(): _start_building(WoodcutterHutScene, Vector2i(WoodcutterHut.SIZE_X, WoodcutterHut.SIZE_Y)))
	_build_builder_button.pressed.connect(
		func(): _start_building(BuilderHutScene, Vector2i(BuilderHut.SIZE_X, BuilderHut.SIZE_Y)))

func _start_building(scene: PackedScene, size: Vector2i) -> void:
	if _building_mode:
		return
	_active_scene = scene
	_active_size = size
	_building_mode = true
	_preview = scene.instantiate()
	_spawn_parent.add_child(_preview)

func _cancel_building() -> void:
	_building_mode = false
	_preview.queue_free()
	_preview = null
	_active_scene = null
	_active_size = Vector2i.ZERO

func _place_building() -> void:
	var mouse_tile := _get_mouse_tile()
	if _is_footprint_blocked(mouse_tile):
		return
	var building := _active_scene.instantiate()
	var building_pos := _footprint_position(mouse_tile)
	building.position = building_pos
	_spawn_parent.add_child(building)
	for dx in _active_size.x:
		for dy in _active_size.y:
			occupied_tiles[Vector2i(mouse_tile.x + dx, mouse_tile.y + dy)] = building
	building.on_placed(_spawn_parent, _tile_size)
	if building is WoodcutterHut:
		_coordination_manager.queue_construction(building)
	_cancel_building()

func _get_mouse_tile() -> Vector2i:
	return _grass_layer.local_to_map(_grass_layer.get_local_mouse_position())

func _footprint_position(top_left_tile: Vector2i) -> Vector2:
	var tl := _grass_layer.map_to_local(top_left_tile)
	var x := tl.x + (_active_size.x - 1) * _tile_size.x / 2.0
	var y := tl.y + (_active_size.y - 0.5) * _tile_size.y
	return Vector2(x, y)

func _is_footprint_blocked(top_left_tile: Vector2i) -> bool:
	for dx in _active_size.x:
		for dy in _active_size.y:
			if occupied_tiles.has(Vector2i(top_left_tile.x + dx, top_left_tile.y + dy)):
				return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not _building_mode:
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_place_building()
			MOUSE_BUTTON_RIGHT:
				_cancel_building()

func _process(_delta: float) -> void:
	if _building_mode:
		_update_preview()

func _update_preview() -> void:
	var mouse_tile := _get_mouse_tile()
	_preview.position = _footprint_position(mouse_tile)
	_preview.modulate = Color(1, 0, 0, 0.7) if _is_footprint_blocked(mouse_tile) else Color(0, 1, 0, 0.7)
