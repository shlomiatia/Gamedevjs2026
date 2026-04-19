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
const ClayKilnScene = preload("res://Scenes/Buildings/ClayKiln/ClayKiln.tscn")
const CoalMineScene = preload("res://Scenes/Buildings/CoalMine/CoalMine.tscn")
const IronMineScene = preload("res://Scenes/Buildings/IronMine/IronMine.tscn")
const SteelMillScene = preload("res://Scenes/Buildings/SteelMill/SteelMill.tscn")
const ToolsmithScene = preload("res://Scenes/Buildings/Toolsmith/Toolsmith.tscn")

var _map: Map = null
var _spawn_parent: Node2D = null
var _building_mode := false
var _preview: Node2D = null
var _active_scene: PackedScene = null
var _active_size: Vector2i = Vector2i.ZERO
var _active_tooltip_key: String = ""
var _coordination_manager: Node = null
var _forest: Forest = null
var _tooltip_manager: BuildingTooltipManager = null
var _placed_keys: Dictionary = {}
var _button_key_pairs: Array = []

# Swapped paths: Builder button is at position 1 (BuildWoodcutterHutButton node),
# Woodcutter button is at position 2 (BuildBuilderHutButton node).
@onready var _build_builder_button: Button = $UI/ButtonPanel/Row1/BuildWoodcutterHutButton
@onready var _build_woodcutter_button: Button = $UI/ButtonPanel/Row1/BuildBuilderHutButton
@onready var _build_sawmill_button: Button = $UI/ButtonPanel/Row1/BuildSawmillButton
@onready var _build_apple_farm_button: Button = $UI/ButtonPanel/Row1/BuildAppleFarmButton
@onready var _build_cider_mill_button: Button = $UI/ButtonPanel/Row1/BuildCiderMillButton
@onready var _build_sheep_farm_button: Button = $UI/ButtonPanel/Row1/BuildSheepFarmButton
@onready var _build_wool_mill_button: Button = $UI/ButtonPanel/Row1/BuildWoolMillButton
@onready var _build_clay_pit_button: Button = $UI/ButtonPanel/Row2/BuildClayPitButton
@onready var _build_clay_kiln_button: Button = $UI/ButtonPanel/Row2/BuildClayKilnButton
@onready var _build_coal_mine_button: Button = $UI/ButtonPanel/Row2/BuildCoalMineButton
@onready var _build_iron_mine_button: Button = $UI/ButtonPanel/Row2/BuildIronMineButton
@onready var _build_steel_mill_button: Button = $UI/ButtonPanel/Row2/BuildSteelMillButton
@onready var _build_toolsmith_button: Button = $UI/ButtonPanel/Row2/BuildToolsmithButton

func setup(map: Map, coordination_manager: Node, forest: Forest) -> void:
    _map = map
    _coordination_manager = coordination_manager
    _forest = forest

func _ready() -> void:
    _spawn_parent = get_parent() as Node2D

    _tooltip_manager = BuildingTooltipManager.new()
    add_child(_tooltip_manager)

    _button_key_pairs = [
        ["BuilderHut",    _build_builder_button],
        ["WoodcutterHut", _build_woodcutter_button],
        ["Sawmill",       _build_sawmill_button],
        ["AppleFarm",     _build_apple_farm_button],
        ["CiderMill",     _build_cider_mill_button],
        ["SheepFarm",     _build_sheep_farm_button],
        ["WoolMill",      _build_wool_mill_button],
        ["ClayPit",       _build_clay_pit_button],
        ["ClayKiln",      _build_clay_kiln_button],
        ["CoalMine",      _build_coal_mine_button],
        ["IronMine",      _build_iron_mine_button],
        ["SteelMill",     _build_steel_mill_button],
        ["Toolsmith",     _build_toolsmith_button],
    ]

    _build_builder_button.pressed.connect(
        func(): _start_building(BuilderHutScene, Vector2i(BuilderHut.SIZE_X, BuilderHut.SIZE_Y), "BuilderHut"))
    _build_woodcutter_button.pressed.connect(
        func(): _start_building(WoodcutterHutScene, Vector2i(WoodcutterHut.SIZE_X, WoodcutterHut.SIZE_Y), "WoodcutterHut"))
    _build_sawmill_button.pressed.connect(
        func(): _start_building(SawmillScene, Vector2i(Sawmill.SIZE_X, Sawmill.SIZE_Y), "Sawmill"))
    _build_apple_farm_button.pressed.connect(
        func(): _start_building(AppleFarmScene, Vector2i(AppleFarm.SIZE_X, AppleFarm.SIZE_Y), "AppleFarm"))
    _build_cider_mill_button.pressed.connect(
        func(): _start_building(CiderMillScene, Vector2i(CiderMill.SIZE_X, CiderMill.SIZE_Y), "CiderMill"))
    _build_sheep_farm_button.pressed.connect(
        func(): _start_building(SheepFarmScene, Vector2i(SheepFarm.SIZE_X, SheepFarm.SIZE_Y), "SheepFarm"))
    _build_wool_mill_button.pressed.connect(
        func(): _start_building(WoolMillScene, Vector2i(WoolMill.SIZE_X, WoolMill.SIZE_Y), "WoolMill"))
    _build_clay_pit_button.pressed.connect(
        func(): _start_building(ClayPitScene, Vector2i(Mine.SIZE_X, Mine.SIZE_Y), "ClayPit"))
    _build_clay_kiln_button.pressed.connect(
        func(): _start_building(ClayKilnScene, Vector2i(ClayKiln.SIZE_X, ClayKiln.SIZE_Y), "ClayKiln"))
    _build_coal_mine_button.pressed.connect(
        func(): _start_building(CoalMineScene, Vector2i(Mine.SIZE_X, Mine.SIZE_Y), "CoalMine"))
    _build_iron_mine_button.pressed.connect(
        func(): _start_building(IronMineScene, Vector2i(Mine.SIZE_X, Mine.SIZE_Y), "IronMine"))
    _build_steel_mill_button.pressed.connect(
        func(): _start_building(SteelMillScene, Vector2i(SteelMill.SIZE_X, SteelMill.SIZE_Y), "SteelMill"))
    _build_toolsmith_button.pressed.connect(
        func(): _start_building(ToolsmithScene, Vector2i(Toolsmith.SIZE_X, Toolsmith.SIZE_Y), "Toolsmith"))

    _tooltip_manager.connect_builder_button(_build_builder_button)
    _tooltip_manager.connect_button(_build_woodcutter_button, "WoodcutterHut")
    _tooltip_manager.connect_button(_build_sawmill_button, "Sawmill")
    _tooltip_manager.connect_button(_build_apple_farm_button, "AppleFarm")
    _tooltip_manager.connect_button(_build_cider_mill_button, "CiderMill")
    _tooltip_manager.connect_button(_build_sheep_farm_button, "SheepFarm")
    _tooltip_manager.connect_button(_build_wool_mill_button, "WoolMill")
    _tooltip_manager.connect_button(_build_clay_pit_button, "ClayPit")
    _tooltip_manager.connect_button(_build_clay_kiln_button, "ClayKiln")
    _tooltip_manager.connect_button(_build_coal_mine_button, "CoalMine")
    _tooltip_manager.connect_button(_build_iron_mine_button, "IronMine")
    _tooltip_manager.connect_button(_build_steel_mill_button, "SteelMill")
    _tooltip_manager.connect_button(_build_toolsmith_button, "Toolsmith")

    _update_buttons()

func _update_buttons() -> void:
    var builder_placed   := _placed_keys.has("BuilderHut")
    var woodcutter_placed := _placed_keys.has("WoodcutterHut")
    var sawmill_placed   := _placed_keys.has("Sawmill")
    var clay_kiln_placed := _placed_keys.has("ClayKiln")

    var enabled: Array = []
    if not builder_placed:
        enabled = ["BuilderHut"]
    elif not (woodcutter_placed and sawmill_placed):
        if not woodcutter_placed:
            enabled.append("WoodcutterHut")
        if not sawmill_placed:
            enabled.append("Sawmill")
    elif not clay_kiln_placed:
        enabled = ["AppleFarm", "CiderMill", "SheepFarm", "WoolMill", "ClayPit", "ClayKiln"]
    else:
        enabled = ["AppleFarm", "CiderMill", "SheepFarm", "WoolMill", "ClayPit", "ClayKiln",
                   "CoalMine", "IronMine", "SteelMill", "Toolsmith"]

    for pair in _button_key_pairs:
        (pair[1] as Button).disabled = pair[0] not in enabled

func _start_building(scene: PackedScene, size: Vector2i, tooltip_key: String) -> void:
    if _building_mode:
        _cancel_building()
    _active_scene = scene
    _active_size = size
    _active_tooltip_key = tooltip_key
    _building_mode = true
    _preview = scene.instantiate()
    _spawn_parent.add_child(_preview)

func _cancel_building() -> void:
    _building_mode = false
    _preview.queue_free()
    _preview = null
    _active_scene = null
    _active_size = Vector2i.ZERO
    _active_tooltip_key = ""

func _place_building() -> void:
    var top_left := _get_footprint_top_left()
    if _is_footprint_blocked(top_left) or not _preview.validate_placement(top_left, _map):
        return
    var building := _active_scene.instantiate()
    building.position = _footprint_position(top_left)
    _spawn_parent.add_child(building)
    _map.set_occupied_tiles_rect(top_left, _active_size, Map.OccupiedType.BLOCK_WORKERS)
    _map.set_occupied_ring(top_left, _active_size, Map.OccupiedType.BLOCK_BUILDING)
    _coordination_manager.register_building(building)
    building.on_placed(_spawn_parent, _map, _coordination_manager, _forest)
    _tooltip_manager.attach_to_building(building, _active_tooltip_key)
    _placed_keys[_active_tooltip_key] = true
    _cancel_building()
    _update_buttons()

func _get_footprint_top_left() -> Vector2i:
    # Offset so the cursor tracks the bottom-center tile of the footprint
    var mouse_tile := _map.get_mouse_tile()
    return mouse_tile - Vector2i(_active_size.x / 2, _active_size.y - 1)

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
