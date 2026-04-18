class_name BuildingManager
extends Node2D

const WoodcutterHutScene = preload("res://Scenes/Buildings/WoodcutterHut/WoodcutterHut.tscn")
const BuilderHutScene = preload("res://Scenes/Buildings/BuilderHut/BuilderHut.tscn")
const SawmillScene = preload("res://Scenes/Buildings/Sawmill/Sawmill.tscn")
const AppleFarmScene = preload("res://Scenes/Buildings/AppleFarm/AppleFarm.tscn")
const CiderMillScene = preload("res://Scenes/Buildings/CiderMill/CiderMill.tscn")
const SheepFarmScene = preload("res://Scenes/Buildings/SheepFarm/SheepFarm.tscn")
const WoolMillScene = preload("res://Scenes/Buildings/WoolMill/WoolMill.tscn")
const ClayPitScene = preload("res://Scenes/Buildings/ClayPit/ClayPit.tscn")

var _map: Map = null
var _spawn_parent: Node2D = null
var _building_mode := false
var _preview: Node2D = null
var _active_scene: PackedScene = null
var _active_size: Vector2i = Vector2i.ZERO
var _coordination_manager: Node = null
var _forest: Forest = null

@onready var _build_woodcutter_button: Button = $UI/BuildWoodcutterHutButton
@onready var _build_builder_button: Button = $UI/BuildBuilderHutButton
@onready var _build_sawmill_button: Button = $UI/BuildSawmillButton
@onready var _build_apple_farm_button: Button = $UI/BuildAppleFarmButton
@onready var _build_cider_mill_button: Button = $UI/BuildCiderMillButton
@onready var _build_sheep_farm_button: Button = $UI/BuildSheepFarmButton
@onready var _build_wool_mill_button: Button = $UI/BuildWoolMillButton
@onready var _build_clay_pit_button: Button = $UI/BuildClayPitButton

func setup(map: Map, coordination_manager: Node, forest: Forest) -> void:
    _map = map
    _coordination_manager = coordination_manager
    _forest = forest

func _ready() -> void:
    _spawn_parent = get_parent() as Node2D
    _build_woodcutter_button.pressed.connect(
        func(): _start_building(WoodcutterHutScene, Vector2i(WoodcutterHut.SIZE_X, WoodcutterHut.SIZE_Y)))
    _build_builder_button.pressed.connect(
        func(): _start_building(BuilderHutScene, Vector2i(BuilderHut.SIZE_X, BuilderHut.SIZE_Y)))
    _build_sawmill_button.pressed.connect(
        func(): _start_building(SawmillScene, Vector2i(Sawmill.SIZE_X, Sawmill.SIZE_Y)))
    _build_apple_farm_button.pressed.connect(
        func(): _start_building(AppleFarmScene, Vector2i(AppleFarm.SIZE_X, AppleFarm.SIZE_Y)))
    _build_cider_mill_button.pressed.connect(
        func(): _start_building(CiderMillScene, Vector2i(CiderMill.SIZE_X, CiderMill.SIZE_Y)))
    _build_sheep_farm_button.pressed.connect(
        func(): _start_building(SheepFarmScene, Vector2i(SheepFarm.SIZE_X, SheepFarm.SIZE_Y)))
    _build_wool_mill_button.pressed.connect(
        func(): _start_building(WoolMillScene, Vector2i(WoolMill.SIZE_X, WoolMill.SIZE_Y)))
    _build_clay_pit_button.pressed.connect(
        func(): _start_building(ClayPitScene, Vector2i(ClayPit.SIZE_X, ClayPit.SIZE_Y)))

func _start_building(scene: PackedScene, size: Vector2i) -> void:
    if _building_mode:
        _cancel_building()
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

func _get_footprint_top_left() -> Vector2i:
    # Offset so the cursor tracks the bottom-center tile of the footprint
    var mouse_tile := _map.get_mouse_tile()
    return mouse_tile - Vector2i(_active_size.x / 2, _active_size.y - 1)

func _place_building() -> void:
    var top_left := _get_footprint_top_left()
    if _is_footprint_blocked(top_left) or not _preview.validate_placement(top_left, _map):
        return
    var building := _active_scene.instantiate()
    building.position = _footprint_position(top_left)
    _spawn_parent.add_child(building)
    _map.set_occupied_tiles_rect(top_left, _active_size, Map.OccupiedType.BLOCK_WORKERS)
    _coordination_manager.register_building(building)
    building.on_placed(_spawn_parent, _map, _coordination_manager, _forest)
    _cancel_building()

func _footprint_position(top_left_tile: Vector2i) -> Vector2:
    var tl := _map.tile_to_world(top_left_tile)
    var tile_size := _map.get_tile_size()
    var x := tl.x + (_active_size.x - 1) * tile_size.x / 2.0
    var y := tl.y + (_active_size.y - 0.5) * tile_size.y
    return Vector2(x, y)

func _is_footprint_blocked(top_left_tile: Vector2i) -> bool:
    for dx in _active_size.x:
        for dy in _active_size.y:
            if _map.occupied_tiles.has(Vector2i(top_left_tile.x + dx, top_left_tile.y + dy)):
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
    var top_left := _get_footprint_top_left()
    var blocked: bool = _is_footprint_blocked(top_left) or not _preview.validate_placement(top_left, _map)
    _preview.position = _footprint_position(top_left)
    _preview.modulate = Color(1, 0, 0, 0.7) if blocked else Color(0, 1, 0, 0.7)
