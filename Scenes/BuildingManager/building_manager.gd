extends Node2D

var occupied_tiles: Dictionary = {}

const WoodcutterScene = preload("res://Scenes/Woodcutter/Woodcutter.tscn")
const WoodcutterScript = preload("res://Scenes/Woodcutter/woodcutter.gd")

var _grass_layer: TileMapLayer
var _spawn_parent: Node2D
var _tile_size: Vector2i
var _building_mode := false
var _preview: Node2D = null

@onready var _build_button: Button = $UI/BuildWoodcutterButton

func _ready() -> void:
    _grass_layer = get_parent().get_node("Grass") as TileMapLayer
    _spawn_parent = get_parent() as Node2D
    _tile_size = _grass_layer.tile_set.tile_size
    _build_button.pressed.connect(_on_build_woodcutter_pressed)

func _on_build_woodcutter_pressed() -> void:
    if _building_mode:
        return
    _building_mode = true
    _preview = WoodcutterScene.instantiate()
    _spawn_parent.add_child(_preview)

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
    _spawn_parent.add_child(building)
    for dx in WoodcutterScript.SIZE_X:
        for dy in WoodcutterScript.SIZE_Y:
            occupied_tiles[Vector2i(mouse_tile.x + dx, mouse_tile.y + dy)] = building
    _cancel_building()

func _get_mouse_tile() -> Vector2i:
    return _grass_layer.local_to_map(_grass_layer.get_local_mouse_position())

func _footprint_position(top_left_tile: Vector2i) -> Vector2:
    var tl := _grass_layer.map_to_local(top_left_tile)
    var x := tl.x + (WoodcutterScript.SIZE_X - 1) * _tile_size.x / 2.0
    var y := tl.y + (WoodcutterScript.SIZE_Y - 0.5) * _tile_size.y
    return Vector2(x, y)

func _is_footprint_blocked(top_left_tile: Vector2i) -> bool:
    for dx in WoodcutterScript.SIZE_X:
        for dy in WoodcutterScript.SIZE_Y:
            if occupied_tiles.has(Vector2i(top_left_tile.x + dx, top_left_tile.y + dy)):
                return true
    return false

func _unhandled_input(event: InputEvent) -> void:
    if not _building_mode:
        return
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                _place_woodcutter()
            MOUSE_BUTTON_RIGHT:
                _cancel_building()

func _process(_delta: float) -> void:
    if _building_mode:
        _update_preview()

func _update_preview() -> void:
    var mouse_tile := _get_mouse_tile()
    _preview.position = _footprint_position(mouse_tile)
    _preview.modulate = Color(1, 0, 0, 0.7) if _is_footprint_blocked(mouse_tile) else Color(0, 1, 0, 0.7)
