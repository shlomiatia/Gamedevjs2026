class_name BuildingManager
extends Node2D

signal building_button_pressed(key: String)
signal building_placed(key: String)

enum CostTier {FREE = 0, PLANK = 1, BRICK = 2}

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
const FromageScene = preload("res://Scenes/Buildings/Fromage/Fromage.tscn")
const WheatFarmScene = preload("res://Scenes/Buildings/WheatFarm/WheatFarm.tscn")
const GritsmillScene = preload("res://Scenes/Buildings/Gritsmill/Gritsmill.tscn")
const BakeryScene = preload("res://Scenes/Buildings/Bakery/Bakery.tscn")
const BreweryScene = preload("res://Scenes/Buildings/Brewery/Brewery.tscn")

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
var _button_key_pairs: Array = [] # [key, btn, tier, base_text_or_null]
var _dropdown_pairs: Array = [] # [trigger_btn, tier]
var _dropdowns: Array = [] # [trigger_btn, popup_control] — for process-based hide
var _valid_tiles: Array[Vector2i] = []
var _overlay_layer: CanvasLayer = null
var _overlay: PlacementOverlay = null

var _build_builder_button: Button = null
var _planks_trigger: Button = null
var _popup_container: Control = null

func setup(map: Map, coordination_manager: Node, forest: Forest) -> void:
    _map = map
    _coordination_manager = coordination_manager
    _forest = forest

func _ready() -> void:
    z_index = 10
    _spawn_parent = get_parent() as Node2D
    $UI.process_mode = Node.PROCESS_MODE_ALWAYS

    _tooltip_manager = BuildingTooltipManager.new()
    add_child(_tooltip_manager)

    _overlay_layer = CanvasLayer.new()
    _overlay_layer.layer = 5
    add_child(_overlay_layer)
    _overlay = PlacementOverlay.new()
    _overlay_layer.add_child(_overlay)

    _build_panel_ui()
    _update_buttons()

func _build_panel_ui() -> void:
    # Full-screen overlay for floating dropdown popups — never intercepts mouse when empty
    _popup_container = Control.new()
    _popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
    _popup_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $UI.add_child(_popup_container)

    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.0, 0.0, 0.0, 0.72)
    style.content_margin_left = 8.0
    style.content_margin_right = 8.0
    style.content_margin_top = 4.0
    style.content_margin_bottom = 4.0
    panel.add_theme_stylebox_override("panel", style)
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
    $UI.add_child(panel)

    var sections_row := HBoxContainer.new()
    sections_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    sections_row.add_theme_constant_override("separation", 0)
    panel.add_child(sections_row)

    _build_construction_section(sections_row)
    sections_row.add_child(VSeparator.new())
    _build_food_section(sections_row)
    sections_row.add_child(VSeparator.new())
    _build_drink_section(sections_row)
    sections_row.add_child(VSeparator.new())
    _build_clothes_section(sections_row)
    sections_row.add_child(VSeparator.new())
    _build_tools_section(sections_row)

func _make_section(parent: HBoxContainer, icon_path: String, label_text: String, mat: ShaderMaterial = null) -> HBoxContainer:
    var section := VBoxContainer.new()
    section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    section.add_theme_constant_override("separation", 2)
    parent.add_child(section)

    var btn_row := HBoxContainer.new()
    btn_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
    btn_row.add_theme_constant_override("separation", 4)
    section.add_child(btn_row)

    var header := HBoxContainer.new()
    header.alignment = BoxContainer.ALIGNMENT_CENTER
    header.add_theme_constant_override("separation", 3)
    var icon := TextureRect.new()
    icon.texture = load(icon_path) as Texture2D
    icon.material = mat
    icon.custom_minimum_size = Vector2(18, 18)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    header.add_child(icon)
    var lbl := Label.new()
    lbl.text = label_text
    lbl.add_theme_font_size_override("font_size", 11)
    lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
    header.add_child(lbl)
    section.add_child(header)

    return btn_row

func _make_direct_btn(text: String, min_w: float = 70.0) -> Button:
    var btn := Button.new()
    btn.text = text
    btn.custom_minimum_size = Vector2(min_w, 40)
    btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return btn

func _make_palette_mat(originals: Array, replacements: Array) -> ShaderMaterial:
    var mat := ShaderMaterial.new()
    mat.shader = load("res://Shaders/pallete_swap.gdshader") as Shader
    for i in originals.size():
        mat.set_shader_parameter("original_%d" % i, originals[i])
        mat.set_shader_parameter("replace_%d" % i, replacements[i])
    return mat

func _make_dropdown(
    parent_row: HBoxContainer,
    icon_path: String,
    tier: int,
    items: Array
) -> Array:
    var section: Control = parent_row.get_parent()

    # Popup lives in _popup_container (full-screen overlay) so it never pushes the bar up
    var popup := PanelContainer.new()
    var ps := StyleBoxFlat.new()
    ps.bg_color = Color(0.08, 0.08, 0.08, 0.92)
    ps.border_color = Color(0.5, 0.5, 0.5, 0.6)
    ps.set_border_width_all(1)
    ps.set_corner_radius_all(3)
    popup.add_theme_stylebox_override("panel", ps)
    popup.visible = false
    _popup_container.add_child(popup)

    var popup_vbox := VBoxContainer.new()
    popup_vbox.add_theme_constant_override("separation", 2)
    popup.add_child(popup_vbox)

    var item_buttons: Array = []
    for item in items:
        var btn := Button.new()
        btn.text = item["text"]
        btn.focus_mode = Control.FOCUS_NONE
        btn.custom_minimum_size = Vector2(0, 34)
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        popup_vbox.add_child(btn)
        item_buttons.append(btn)

        var sc: PackedScene = item["scene"]
        var sz := Vector2i(item["size_x"], item["size_y"])
        var key: String = item["key"]
        btn.pressed.connect(func(): _start_building(sc, sz, key))
        _tooltip_manager.connect_button(btn, key)

    var trigger := Button.new()
    trigger.focus_mode = Control.FOCUS_NONE
    if icon_path != "":
        trigger.icon = load(icon_path) as Texture2D
    trigger.custom_minimum_size = Vector2(44, 40)
    parent_row.add_child(trigger)

    trigger.mouse_entered.connect(func():
        if not trigger.disabled:
            popup.visible = true
    )

    _dropdowns.append([trigger, popup, section])
    _dropdown_pairs.append([trigger, tier])
    return item_buttons

func _build_construction_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/house.png", "Construction")

    var builder_btn := _make_direct_btn("Builder")
    builder_btn.focus_mode = Control.FOCUS_NONE
    row.add_child(builder_btn)
    _build_builder_button = builder_btn
    builder_btn.pressed.connect(func(): _start_building(BuilderHutScene, Vector2i(BuilderHut.SIZE_X, BuilderHut.SIZE_Y), "BuilderHut"))
    _tooltip_manager.connect_builder_button(builder_btn)
    _button_key_pairs.append(["BuilderHut", builder_btn, -1, "Builder"])

    var planks_btns := _make_dropdown(row, "res://Textures/planks.png", CostTier.FREE, [
        {"key": "Sawmill", "scene": SawmillScene, "size_x": Sawmill.SIZE_X, "size_y": Sawmill.SIZE_Y, "text": "Sawmill"},
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": "Woodcutter"},
        
    ])
    _planks_trigger = _dropdown_pairs.back()[0]
    _button_key_pairs.append(["Sawmill", planks_btns[0], CostTier.FREE, "Sawmill"])
    _button_key_pairs.append(["WoodcutterHut", planks_btns[1], CostTier.FREE, "Woodcutter"])
    

    var bricks_btns := _make_dropdown(row, "res://Textures/brick.png", CostTier.PLANK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": "Woodcutter"},
        {"key": "ClayKiln", "scene": ClayKilnScene, "size_x": ClayKiln.SIZE_X, "size_y": ClayKiln.SIZE_Y, "text": "Clay Kiln"},
        {"key": "ClayPit", "scene": ClayPitScene, "size_x": Mine.SIZE_X, "size_y": Mine.SIZE_Y, "text": "Clay Pit"},
    ])
    
    _button_key_pairs.append(["WoodcutterHut", bricks_btns[0], CostTier.FREE, "Woodcutter"])
    _button_key_pairs.append(["ClayKiln", bricks_btns[1], CostTier.PLANK, "Clay Kiln"])
    _button_key_pairs.append(["ClayPit", bricks_btns[2], CostTier.PLANK, "Clay Pit"])

func _build_food_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/food.png", "Food")

    var apple_btn := _make_direct_btn("Apple Farm")
    apple_btn.focus_mode = Control.FOCUS_NONE
    row.add_child(apple_btn)
    apple_btn.pressed.connect(func(): _start_building(AppleFarmScene, Vector2i(AppleFarm.SIZE_X, AppleFarm.SIZE_Y), "AppleFarm"))
    _tooltip_manager.connect_button(apple_btn, "AppleFarm")
    _button_key_pairs.append(["AppleFarm", apple_btn, CostTier.PLANK, "Apple Farm"])

    var cheese_btns := _make_dropdown(row, "res://Textures/cheese.png", CostTier.BRICK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": "Woodcutter"},
        {"key": "Fromage", "scene": FromageScene, "size_x": Fromage.SIZE_X, "size_y": Fromage.SIZE_Y, "text": "Fromage"},
        {"key": "SheepFarm", "scene": SheepFarmScene, "size_x": SheepFarm.SIZE_X, "size_y": SheepFarm.SIZE_Y, "text": "Sheep Farm"},
    ])
    _button_key_pairs.append(["WoodcutterHut", cheese_btns[0], CostTier.FREE, "Woodcutter"])
    _button_key_pairs.append(["Fromage", cheese_btns[1], CostTier.BRICK, "Fromage"])
    _button_key_pairs.append(["SheepFarm", cheese_btns[2], CostTier.PLANK, "Sheep Farm"])

    var bread_btns := _make_dropdown(row, "res://Textures/bread.png.png", CostTier.BRICK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": "Woodcutter"},
        {"key": "Bakery", "scene": BakeryScene, "size_x": Bakery.SIZE_X, "size_y": Bakery.SIZE_Y, "text": "Bakery"},
        {"key": "Gritsmill", "scene": GritsmillScene, "size_x": Gritsmill.SIZE_X, "size_y": Gritsmill.SIZE_Y, "text": "Gritsmill"},
        {"key": "WheatFarm", "scene": WheatFarmScene, "size_x": WheatFarm.SIZE_X, "size_y": WheatFarm.SIZE_Y, "text": "Wheat Farm"},
    ])
    _button_key_pairs.append(["WoodcutterHut", bread_btns[0], CostTier.FREE, "Woodcutter"])
    _button_key_pairs.append(["Bakery", bread_btns[1], CostTier.BRICK, "Bakery"])
    _button_key_pairs.append(["Gritsmill", bread_btns[2], CostTier.PLANK, "Gritsmill"])
    _button_key_pairs.append(["WheatFarm", bread_btns[3], CostTier.PLANK, "Wheat Farm"])

func _build_drink_section(parent: HBoxContainer) -> void:
    var drink_mat := ShaderMaterial.new()
    drink_mat.shader = load("res://Shaders/pallete_swap.gdshader") as Shader
    drink_mat.set_shader_parameter("original_0", Color(0.972549, 0.250980, 0.105882, 1))
    drink_mat.set_shader_parameter("replace_0", Color(0, 0, 0, 0))
    drink_mat.set_shader_parameter("original_1", Color(0.741176, 0.152941, 0.035294, 1))
    drink_mat.set_shader_parameter("replace_1", Color(0, 0, 0, 0))
    drink_mat.set_shader_parameter("original_2", Color(0.486275, 0.070588, 0.168627, 1))
    drink_mat.set_shader_parameter("replace_2", Color(0, 0, 0, 0))
    drink_mat.set_shader_parameter("original_3", Color(0.615686, 0.113725, 0.101961, 1))
    drink_mat.set_shader_parameter("replace_3", Color(0, 0, 0, 0))
    var row := _make_section(parent, "res://Textures/cider.png", "Drink", drink_mat)

    var _orig := [
        Color(0.97255, 0.25098, 0.10588), Color(0.74118, 0.15294, 0.03529),
        Color(0.48627, 0.07059, 0.16863), Color(0.6156863, 0.11372549, 0.10196),
    ]

    var sheep_btn := _make_direct_btn("Sheep Farm")
    sheep_btn.focus_mode = Control.FOCUS_NONE
    sheep_btn.custom_minimum_size = Vector2(44, 40)
    row.add_child(sheep_btn)
    sheep_btn.pressed.connect(func(): _start_building(SheepFarmScene, Vector2i(SheepFarm.SIZE_X, SheepFarm.SIZE_Y), "SheepFarm"))
    _tooltip_manager.connect_button(sheep_btn, "SheepFarm")
    _button_key_pairs.append(["SheepFarm", sheep_btn, CostTier.PLANK, "Sheep Farm"])

    var cider_btns := _make_dropdown(row, "res://Textures/cider.png", CostTier.PLANK, [
        {"key": "CiderMill", "scene": CiderMillScene, "size_x": CiderMill.SIZE_X, "size_y": CiderMill.SIZE_Y, "text": "Cider Mill"},
        {"key": "AppleFarm", "scene": AppleFarmScene, "size_x": AppleFarm.SIZE_X, "size_y": AppleFarm.SIZE_Y, "text": "Apple Farm"},
    ])
    _button_key_pairs.append(["CiderMill", cider_btns[0], CostTier.PLANK, "Cider Mill"])
    _button_key_pairs.append(["AppleFarm", cider_btns[1], CostTier.PLANK, "Apple Farm"])

    # Beer dropdown with beer-coloured cider icon
    var beer_btns := _make_dropdown(row, "res://Textures/beer.png", CostTier.BRICK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": "Woodcutter"},
        {"key": "Brewery", "scene": BreweryScene, "size_x": Brewery.SIZE_X, "size_y": Brewery.SIZE_Y, "text": "Brewery"},
        {"key": "WheatFarm", "scene": WheatFarmScene, "size_x": WheatFarm.SIZE_X, "size_y": WheatFarm.SIZE_Y, "text": "Wheat Farm"},
        
    ])
    _button_key_pairs.append(["WoodcutterHut", beer_btns[0], CostTier.FREE, "Woodcutter"])
    _button_key_pairs.append(["Brewery", beer_btns[1], CostTier.BRICK, "Brewery"])
    _button_key_pairs.append(["WheatFarm", beer_btns[2], CostTier.PLANK, "Wheat Farm"])

func _build_clothes_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/Clothes.png", "Clothes")

    var clothes_btns := _make_dropdown(row, "res://Textures/Clothes.png", CostTier.PLANK, [
        {"key": "WoolMill", "scene": WoolMillScene, "size_x": WoolMill.SIZE_X, "size_y": WoolMill.SIZE_Y, "text": "Wool Mill"},
        {"key": "SheepFarm", "scene": SheepFarmScene, "size_x": SheepFarm.SIZE_X, "size_y": SheepFarm.SIZE_Y, "text": "Sheep Farm"},
    ])
    _button_key_pairs.append(["WoolMill", clothes_btns[0], CostTier.PLANK, "Wool Mill"])
    _button_key_pairs.append(["SheepFarm", clothes_btns[1], CostTier.PLANK, "Sheep Farm"])
    

func _build_tools_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/tool.png", "Tools")

    var tools_btns := _make_dropdown(row, "res://Textures/tool.png", CostTier.BRICK, [
        {"key": "Toolsmith", "scene": ToolsmithScene, "size_x": Toolsmith.SIZE_X, "size_y": Toolsmith.SIZE_Y, "text": "Toolsmith"},
        {"key": "SteelMill", "scene": SteelMillScene, "size_x": SteelMill.SIZE_X, "size_y": SteelMill.SIZE_Y, "text": "Steel Mill"},
        {"key": "IronMine", "scene": IronMineScene, "size_x": Mine.SIZE_X, "size_y": Mine.SIZE_Y, "text": "Iron Mine"},
        {"key": "CoalMine", "scene": CoalMineScene, "size_x": Mine.SIZE_X, "size_y": Mine.SIZE_Y, "text": "Coal Mine"},
    ])
    _button_key_pairs.append(["Toolsmith", tools_btns[0], CostTier.BRICK, "Toolsmith"])
    _button_key_pairs.append(["SteelMill", tools_btns[1], CostTier.BRICK, "Steel Mill"])
    _button_key_pairs.append(["IronMine", tools_btns[2], CostTier.PLANK, "Iron Mine"])
    _button_key_pairs.append(["CoalMine", tools_btns[3], CostTier.PLANK, "Coal Mine"])

    
func _update_buttons() -> void:
    var builder_placed := _placed_keys.has("BuilderHut")
    var wc_saw_placed := _placed_keys.has("WoodcutterHut") and _placed_keys.has("Sawmill")
    var clay_kiln_placed := _placed_keys.has("ClayKiln")

    var max_tier: int
    if not wc_saw_placed:
        max_tier = CostTier.FREE
    elif not clay_kiln_placed:
        max_tier = CostTier.PLANK
    else:
        max_tier = CostTier.BRICK

    for pair in _button_key_pairs:
        var key: String = pair[0]
        var btn: Button = pair[1]
        var tier: int = pair[2]
        var base_text = pair[3]
        var count: int = _placed_keys.get(key, 0)

        if base_text != null:
            btn.text = "%s (%d)" % [base_text, count] if count > 0 else base_text

        if not builder_placed:
            btn.disabled = key != "BuilderHut"
        elif key == "BuilderHut":
            btn.disabled = not wc_saw_placed
        elif key == "WoodcutterHut" or key == "Sawmill":
            btn.disabled = (_placed_keys.has(key) and not wc_saw_placed) or tier > max_tier
        else:
            btn.disabled = tier > max_tier

    for pair in _dropdown_pairs:
        var trigger: Button = pair[0]
        var tier: int = pair[1]
        if not builder_placed:
            trigger.disabled = true
        elif not wc_saw_placed:
            trigger.disabled = tier != CostTier.FREE
        elif not clay_kiln_placed:
            trigger.disabled = tier > CostTier.PLANK
        else:
            trigger.disabled = false

func _start_building(scene: PackedScene, size: Vector2i, tooltip_key: String) -> void:
    if _building_mode:
        _cancel_building()
    _active_scene = scene
    _active_size = size
    _active_tooltip_key = tooltip_key
    _building_mode = true
    _preview = scene.instantiate()
    if _preview_has_mill():
        _active_size.y = 2
    _spawn_parent.add_child(_preview)
    var data := _compute_placement_data(size)
    _valid_tiles = data[0]
    _overlay.show_rects(data[1])
    building_button_pressed.emit(tooltip_key)

func _cancel_building() -> void:
    _building_mode = false
    _preview.queue_free()
    _preview = null
    _active_scene = null
    _active_size = Vector2i.ZERO
    _active_tooltip_key = ""
    _valid_tiles = []
    _overlay.clear()

func _place_building() -> void:
    var top_left := _get_footprint_top_left()
    if _is_footprint_blocked(top_left) or not _preview.validate_placement(top_left, _map):
        return
    var building := _active_scene.instantiate()
    building.position = _footprint_position(top_left)
    _spawn_parent.add_child(building)
    _map.set_occupied_tiles_rect(top_left, _active_size, Map.OccupiedType.BLOCK_WORKERS)
    _map.set_occupied_ring(top_left, _active_size, Map.OccupiedType.BLOCK_BUILDING)
    _add_nav_obstacle(building, _active_size)
    _coordination_manager.register_building(building)
    building.on_placed(_spawn_parent, _map, _coordination_manager, _forest)
    _tooltip_manager.attach_to_building(building, _active_tooltip_key)
    _placed_keys[_active_tooltip_key] = _placed_keys.get(_active_tooltip_key, 0) + 1
    var placed_key := _active_tooltip_key
    _cancel_building()
    _update_buttons()
    building_placed.emit(placed_key)

func _add_nav_obstacle(building: Node2D, size: Vector2i) -> void:
    var ts := _map.get_tile_size()
    var hw := size.x * ts.x * 0.5
    var h := size.y * ts.y
    var obstacle := NavigationObstacle2D.new()
    obstacle.avoidance_enabled = true
    obstacle.vertices = PackedVector2Array([
        Vector2(-hw, -h), Vector2(hw, -h), Vector2(hw, 0.0), Vector2(-hw, 0.0)
    ])
    building.add_child(obstacle)
    var p := building.position
    var e := 4.0
    _map.add_nav_hole(PackedVector2Array([
        p + Vector2(-hw - e, -h - e), p + Vector2(-hw - e, e),
        p + Vector2(hw + e, e), p + Vector2(hw + e, -h - e)
    ]))

func _get_footprint_top_left() -> Vector2i:
    var mouse_tile := _map.get_mouse_tile()
    return mouse_tile - Vector2i(_active_size.x >> 1, _active_size.y - 1)

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
        _update_arrow()
        _overlay.queue_redraw()
    _update_dropdowns()

func _update_dropdowns() -> void:
    var mouse_pos := get_viewport().get_mouse_position()
    for dd in _dropdowns:
        var trigger: Button = dd[0]
        var popup: Control = dd[1]
        var section: Control = dd[2]
        if not popup.visible:
            continue
        # Size popup to match section width and reposition above section every frame
        var section_rect := section.get_global_rect()
        popup.custom_minimum_size = Vector2(section_rect.size.x, 0)
        popup.position = Vector2(section_rect.position.x, section_rect.position.y - popup.size.y)
        # Hide when mouse is outside both trigger and popup
        var trigger_rect := trigger.get_global_rect()
        var popup_rect := Rect2(popup.global_position, popup.size)
        if not trigger_rect.grow(2.0).has_point(mouse_pos) and not popup_rect.grow(2.0).has_point(mouse_pos):
            popup.visible = false

func _update_preview() -> void:
    var top_left := _get_footprint_top_left()
    var blocked: bool = _is_footprint_blocked(top_left) or not _preview.validate_placement(top_left, _map)
    _preview.position = _footprint_position(top_left)
    _preview.modulate = Color(1, 1, 1, 0.5)
    var tile_size := _map.get_tile_size()
    var half := Vector2(tile_size) * 0.5
    var tl_world := _map.tile_to_world(top_left) - half
    _overlay.set_footprint(Rect2(tl_world, Vector2(_active_size) * Vector2(tile_size)), not blocked)

func _update_arrow() -> void:
    if _valid_tiles.is_empty():
        _overlay.set_arrow(Vector2.ZERO, false)
        return
    var vt := get_viewport().get_canvas_transform()
    var inv := vt.affine_inverse()
    var vp_size := get_viewport_rect().size
    var world_tl := inv * Vector2.ZERO
    var world_br := inv * vp_size
    var world_visible := Rect2(world_tl, world_br - world_tl)
    var building_comp := _preview.get_node_or_null("Building") as BuildingComponent
    var is_mill := building_comp != null and building_comp.has_mill
    var is_mine := _preview is Mine
    if is_mill:
        _overlay.center_text = "Mills must be built next to the river."
    elif is_mine:
        _overlay.center_text = "Mines must be built next to the mountain."
    else:
        _overlay.center_text = ""
        
    for tile in _valid_tiles:
        if world_visible.has_point(_map.tile_to_world(tile)):
            _overlay.set_arrow(Vector2.ZERO, false)
            return
    
    if is_mill:
        _overlay.set_arrow(Vector2.UP, true)
    elif is_mine:
        _overlay.set_arrow(Vector2.DOWN, true)
    else:
        var vp_center_world := inv * (vp_size * 0.5)
        var nearest_dir := Vector2.ZERO
        var nearest_dist := INF
        for tile in _valid_tiles:
            var wp := _map.tile_to_world(tile)
            var d := vp_center_world.distance_squared_to(wp)
            if d < nearest_dist:
                nearest_dist = d
                nearest_dir = (wp - vp_center_world).normalized()
        _overlay.set_arrow(nearest_dir, true)

func get_builder_button_rect() -> Rect2:
    return _build_builder_button.get_global_rect()

func get_woodcutter_sawmill_rect() -> Rect2:
    return _planks_trigger.get_global_rect()

func _compute_placement_data(size: Vector2i) -> Array:
    var tile_size := _map.get_tile_size()
    var half := Vector2(tile_size) * 0.5
    var bounds := _map.get_tile_bounds()

    var is_mill := _preview_has_mill()
    var is_mine := _preview is Mine

    var valid_rows: Array[int] = []
    if is_mill:
        valid_rows.append(Map.RIVER_ROW + 2)
        valid_rows.append(Map.RIVER_ROW + 3)
    elif is_mine:
        var mine_top := Map.LEVEL_HEIGHT - 6 - size.y
        for i in size.y:
            valid_rows.append(mine_top + i)

    var invalid_rects: Array[Rect2] = []
    var valid_tiles: Array[Vector2i] = []

    for tx in range(bounds.position.x, bounds.end.x):
        for ty in range(bounds.position.y, bounds.end.y):
            var tile := Vector2i(tx, ty)
            var invalid: bool = _map.occupied_tiles.has(tile)
            if not invalid and not valid_rows.is_empty():
                invalid = ty not in valid_rows
            if invalid:
                var center := _map.tile_to_world(tile)
                invalid_rects.append(Rect2(center - half, Vector2(tile_size)))
            else:
                valid_tiles.append(tile)

    return [valid_tiles, invalid_rects]

func _preview_has_mill() -> bool:
    var building_comp := _preview.get_node_or_null("Building") as BuildingComponent
    return building_comp != null and building_comp.has_mill