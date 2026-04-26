class_name BuildingManager
extends Node2D

signal building_button_pressed(key: String)
signal building_placed(key: String)
signal planks_dropdown_hovered
signal food_section_hovered

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
const FishermanHutScene = preload("res://Scenes/Buildings/FishermanHut/FishermanHut.tscn")
const SmokehouseScene = preload("res://Scenes/Buildings/Smokehouse/Smokehouse.tscn")
const FlaxFarmScene = preload("res://Scenes/Buildings/FlaxFarm/FlaxFarm.tscn")
const WeavingMillScene = preload("res://Scenes/Buildings/WeavingMill/WeavingMill.tscn")

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
var _click_player: AudioStreamPlayer = null

var _build_builder_button: Button = null
var _planks_trigger: Button = null
var _food_section: Control = null
var _popup_container: Control = null

func setup(map: Map, coordination_manager: Node, forest: Forest) -> void:
    _map = map
    _coordination_manager = coordination_manager
    _forest = forest
    if _overlay != null:
        _overlay.setup(_map)

func set_ui_visible(val: bool) -> void:
    $UI.visible = val

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

    _click_player = AudioStreamPlayer.new()
    _click_player.stream = load("res://Audio/click.wav") as AudioStream
    add_child(_click_player)

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
    style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
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
    lbl.label_settings = preload("res://Themes/label_small.tres")
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
    ps.bg_color = Color(0.0, 0.0, 0.0, 0.4)
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
        var item_tier: int = item.get("tier", CostTier.FREE)
        btn.pressed.connect(func(): _start_building(sc, sz, key))
        if item_tier == CostTier.BRICK:
            _tooltip_manager.connect_button(btn, key, func(): return "" if _placed_keys.has("ClayKiln") else "Requires clay kiln")
        else:
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

    var builder_btn := _make_direct_btn(BuilderHut.BUILDING_NAME)
    builder_btn.focus_mode = Control.FOCUS_NONE
    row.add_child(builder_btn)
    _build_builder_button = builder_btn
    builder_btn.pressed.connect(func(): _start_building(BuilderHutScene, Vector2i(BuilderHut.SIZE_X, BuilderHut.SIZE_Y), "BuilderHut"))
    _tooltip_manager.connect_builder_button(builder_btn)
    _button_key_pairs.append(["BuilderHut", builder_btn, -1, BuilderHut.BUILDING_NAME])

    var planks_btns := _make_dropdown(row, "res://Textures/planks.png", CostTier.FREE, [
        {"key": "Sawmill", "scene": SawmillScene, "size_x": Sawmill.SIZE_X, "size_y": Sawmill.SIZE_Y, "text": Sawmill.BUILDING_NAME, "tier": CostTier.FREE},
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": WoodcutterHut.BUILDING_NAME, "tier": CostTier.FREE},
    ])
    _planks_trigger = _dropdown_pairs.back()[0]
    _planks_trigger.mouse_entered.connect(func(): planks_dropdown_hovered.emit())
    _button_key_pairs.append(["Sawmill", planks_btns[0], CostTier.FREE, Sawmill.BUILDING_NAME])
    _button_key_pairs.append(["WoodcutterHut", planks_btns[1], CostTier.FREE, WoodcutterHut.BUILDING_NAME])

    var bricks_btns := _make_dropdown(row, "res://Textures/brick.png", CostTier.PLANK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": WoodcutterHut.BUILDING_NAME, "tier": CostTier.FREE},
        {"key": "ClayKiln", "scene": ClayKilnScene, "size_x": ClayKiln.SIZE_X, "size_y": ClayKiln.SIZE_Y, "text": ClayKiln.BUILDING_NAME, "tier": CostTier.PLANK},
        {"key": "ClayPit", "scene": ClayPitScene, "size_x": Mine.SIZE_X, "size_y": Mine.SIZE_Y, "text": "Clay pit", "tier": CostTier.PLANK},
    ])

    _button_key_pairs.append(["WoodcutterHut", bricks_btns[0], CostTier.FREE, WoodcutterHut.BUILDING_NAME])
    _button_key_pairs.append(["ClayKiln", bricks_btns[1], CostTier.PLANK, ClayKiln.BUILDING_NAME])
    _button_key_pairs.append(["ClayPit", bricks_btns[2], CostTier.PLANK, "Clay pit"])

func _build_food_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/food.png", "Food")
    _food_section = row.get_parent()
    _food_section.mouse_entered.connect(func(): food_section_hovered.emit())

    var apple_btns := _make_dropdown(row, "res://Textures/apple.png", CostTier.PLANK, [
        {"key": "AppleFarm", "scene": AppleFarmScene, "size_x": AppleFarm.SIZE_X, "size_y": AppleFarm.SIZE_Y, "text": AppleFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["AppleFarm", apple_btns[0], CostTier.PLANK, AppleFarm.BUILDING_NAME])

    var cheese_btns := _make_dropdown(row, "res://Textures/cheese.png", CostTier.BRICK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": WoodcutterHut.BUILDING_NAME, "tier": CostTier.FREE},
        {"key": "Fromage", "scene": FromageScene, "size_x": Fromage.SIZE_X, "size_y": Fromage.SIZE_Y, "text": Fromage.BUILDING_NAME, "tier": CostTier.BRICK},
        {"key": "SheepFarm", "scene": SheepFarmScene, "size_x": SheepFarm.SIZE_X, "size_y": SheepFarm.SIZE_Y, "text": SheepFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["WoodcutterHut", cheese_btns[0], CostTier.FREE, WoodcutterHut.BUILDING_NAME])
    _button_key_pairs.append(["Fromage", cheese_btns[1], CostTier.BRICK, Fromage.BUILDING_NAME])
    _button_key_pairs.append(["SheepFarm", cheese_btns[2], CostTier.PLANK, SheepFarm.BUILDING_NAME])

    var bread_btns := _make_dropdown(row, "res://Textures/bread.png.png", CostTier.BRICK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": WoodcutterHut.BUILDING_NAME, "tier": CostTier.FREE},
        {"key": "Bakery", "scene": BakeryScene, "size_x": Bakery.SIZE_X, "size_y": Bakery.SIZE_Y, "text": Bakery.BUILDING_NAME, "tier": CostTier.BRICK},
        {"key": "Gritsmill", "scene": GritsmillScene, "size_x": Gritsmill.SIZE_X, "size_y": Gritsmill.SIZE_Y, "text": Gritsmill.BUILDING_NAME, "tier": CostTier.PLANK},
        {"key": "WheatFarm", "scene": WheatFarmScene, "size_x": WheatFarm.SIZE_X, "size_y": WheatFarm.SIZE_Y, "text": WheatFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["WoodcutterHut", bread_btns[0], CostTier.FREE, WoodcutterHut.BUILDING_NAME])
    _button_key_pairs.append(["Bakery", bread_btns[1], CostTier.BRICK, Bakery.BUILDING_NAME])
    _button_key_pairs.append(["Gritsmill", bread_btns[2], CostTier.PLANK, Gritsmill.BUILDING_NAME])
    _button_key_pairs.append(["WheatFarm", bread_btns[3], CostTier.PLANK, WheatFarm.BUILDING_NAME])

    var fish_btns := _make_dropdown(row, "res://Textures/smoked fish.png", CostTier.BRICK, [
        {"key": "Smokehouse", "scene": SmokehouseScene, "size_x": Smokehouse.SIZE_X, "size_y": Smokehouse.SIZE_Y, "text": Smokehouse.BUILDING_NAME, "tier": CostTier.BRICK},
        {"key": "FishermanHut", "scene": FishermanHutScene, "size_x": FishermanHut.SIZE_X, "size_y": FishermanHut.SIZE_Y, "text": FishermanHut.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["Smokehouse", fish_btns[0], CostTier.BRICK, Smokehouse.BUILDING_NAME])
    _button_key_pairs.append(["FishermanHut", fish_btns[1], CostTier.PLANK, FishermanHut.BUILDING_NAME])

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

    var sheep_btns := _make_dropdown(row, "res://Textures/milk.png", CostTier.PLANK, [
        {"key": "SheepFarm", "scene": SheepFarmScene, "size_x": SheepFarm.SIZE_X, "size_y": SheepFarm.SIZE_Y, "text": SheepFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["SheepFarm", sheep_btns[0], CostTier.PLANK, SheepFarm.BUILDING_NAME])

    var cider_btns := _make_dropdown(row, "res://Textures/cider.png", CostTier.PLANK, [
        {"key": "CiderMill", "scene": CiderMillScene, "size_x": CiderMill.SIZE_X, "size_y": CiderMill.SIZE_Y, "text": CiderMill.BUILDING_NAME, "tier": CostTier.PLANK},
        {"key": "AppleFarm", "scene": AppleFarmScene, "size_x": AppleFarm.SIZE_X, "size_y": AppleFarm.SIZE_Y, "text": AppleFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["CiderMill", cider_btns[0], CostTier.PLANK, CiderMill.BUILDING_NAME])
    _button_key_pairs.append(["AppleFarm", cider_btns[1], CostTier.PLANK, AppleFarm.BUILDING_NAME])

    var beer_btns := _make_dropdown(row, "res://Textures/beer.png", CostTier.BRICK, [
        {"key": "WoodcutterHut", "scene": WoodcutterHutScene, "size_x": WoodcutterHut.SIZE_X, "size_y": WoodcutterHut.SIZE_Y, "text": WoodcutterHut.BUILDING_NAME, "tier": CostTier.FREE},
        {"key": "Brewery", "scene": BreweryScene, "size_x": Brewery.SIZE_X, "size_y": Brewery.SIZE_Y, "text": Brewery.BUILDING_NAME, "tier": CostTier.BRICK},
        {"key": "WheatFarm", "scene": WheatFarmScene, "size_x": WheatFarm.SIZE_X, "size_y": WheatFarm.SIZE_Y, "text": WheatFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["WoodcutterHut", beer_btns[0], CostTier.FREE, WoodcutterHut.BUILDING_NAME])
    _button_key_pairs.append(["Brewery", beer_btns[1], CostTier.BRICK, Brewery.BUILDING_NAME])
    _button_key_pairs.append(["WheatFarm", beer_btns[2], CostTier.PLANK, WheatFarm.BUILDING_NAME])

func _build_clothes_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/Clothes.png", "Clothes")

    var clothes_btns := _make_dropdown(row, "res://Textures/Clothes.png", CostTier.PLANK, [
        {"key": "WoolMill", "scene": WoolMillScene, "size_x": WoolMill.SIZE_X, "size_y": WoolMill.SIZE_Y, "text": WoolMill.BUILDING_NAME, "tier": CostTier.PLANK},
        {"key": "SheepFarm", "scene": SheepFarmScene, "size_x": SheepFarm.SIZE_X, "size_y": SheepFarm.SIZE_Y, "text": SheepFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["WoolMill", clothes_btns[0], CostTier.PLANK, WoolMill.BUILDING_NAME])
    _button_key_pairs.append(["SheepFarm", clothes_btns[1], CostTier.PLANK, SheepFarm.BUILDING_NAME])

    var flax_btns := _make_dropdown(row, "res://Textures/flax clothes.png", CostTier.PLANK, [
        {"key": "WeavingMill", "scene": WeavingMillScene, "size_x": WeavingMill.SIZE_X, "size_y": WeavingMill.SIZE_Y, "text": WeavingMill.BUILDING_NAME, "tier": CostTier.PLANK},
        {"key": "FlaxFarm", "scene": FlaxFarmScene, "size_x": FlaxFarm.SIZE_X, "size_y": FlaxFarm.SIZE_Y, "text": FlaxFarm.BUILDING_NAME, "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["WeavingMill", flax_btns[0], CostTier.PLANK, WeavingMill.BUILDING_NAME])
    _button_key_pairs.append(["FlaxFarm", flax_btns[1], CostTier.PLANK, FlaxFarm.BUILDING_NAME])
    

func _build_tools_section(parent: HBoxContainer) -> void:
    var row := _make_section(parent, "res://Textures/tool.png", "Tools")

    var tools_btns := _make_dropdown(row, "res://Textures/tool.png", CostTier.BRICK, [
        {"key": "Toolsmith", "scene": ToolsmithScene, "size_x": Toolsmith.SIZE_X, "size_y": Toolsmith.SIZE_Y, "text": Toolsmith.BUILDING_NAME, "tier": CostTier.BRICK},
        {"key": "SteelMill", "scene": SteelMillScene, "size_x": SteelMill.SIZE_X, "size_y": SteelMill.SIZE_Y, "text": SteelMill.BUILDING_NAME, "tier": CostTier.BRICK},
        {"key": "IronMine", "scene": IronMineScene, "size_x": Mine.SIZE_X, "size_y": Mine.SIZE_Y, "text": "Iron mine", "tier": CostTier.PLANK},
        {"key": "CoalMine", "scene": CoalMineScene, "size_x": Mine.SIZE_X, "size_y": Mine.SIZE_Y, "text": "Coal mine", "tier": CostTier.PLANK},
    ])
    _button_key_pairs.append(["Toolsmith", tools_btns[0], CostTier.BRICK, Toolsmith.BUILDING_NAME])
    _button_key_pairs.append(["SteelMill", tools_btns[1], CostTier.BRICK, SteelMill.BUILDING_NAME])
    _button_key_pairs.append(["IronMine", tools_btns[2], CostTier.PLANK, "Iron mine"])
    _button_key_pairs.append(["CoalMine", tools_btns[3], CostTier.PLANK, "Coal mine"])

    
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
        else:
            trigger.disabled = false

func _start_building(scene: PackedScene, size: Vector2i, tooltip_key: String) -> void:
    if _click_player != null:
        _click_player.play()
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
    _overlay.show_tiles(data[1])
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
    (building.get_node("Building") as BuildingComponent).register_on_map(_map, top_left)
    _coordination_manager.register_building(building)
    building.on_placed(_spawn_parent, _map, _coordination_manager, _forest)
    _tooltip_manager.attach_to_building(building, _active_tooltip_key)
    _placed_keys[_active_tooltip_key] = _placed_keys.get(_active_tooltip_key, 0) + 1
    var placed_key := _active_tooltip_key
    var bc := building.get_node_or_null("Building") as BuildingComponent
    if bc != null:
        bc.cancel_requested.connect(func():
            _placed_keys[placed_key] = maxi(0, _placed_keys.get(placed_key, 0) - 1)
            _update_buttons()
        )
    _cancel_building()
    _update_buttons()
    building_placed.emit(placed_key)

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
    _overlay.set_footprint(top_left, _active_size, not blocked)

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
        _overlay.center_text = "Mills need water to run. Build your mills on the riverbank. "
    elif is_mine:
        _overlay.center_text = "Best mining is in the mountains, so that's where your mines should be."
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

func get_food_section_rect() -> Rect2:
    return _food_section.get_global_rect()

func _compute_placement_data(size: Vector2i) -> Array:
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

    var invalid_tiles: Array[Vector2i] = []
    var valid_tiles: Array[Vector2i] = []

    for tx in range(bounds.position.x, bounds.end.x):
        for ty in range(bounds.position.y, bounds.end.y):
            var tile := Vector2i(tx, ty)
            var invalid: bool = _map.occupied_tiles.has(tile)
            if not invalid and not valid_rows.is_empty():
                invalid = ty not in valid_rows
            if invalid:
                invalid_tiles.append(tile)
            else:
                valid_tiles.append(tile)

    return [valid_tiles, invalid_tiles]

func _preview_has_mill() -> bool:
    var building_comp := _preview.get_node_or_null("Building") as BuildingComponent
    return building_comp != null and building_comp.has_mill