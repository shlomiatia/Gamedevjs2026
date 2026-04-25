class_name BuildingTooltip
extends CanvasLayer

# Integer keys match CoordinationManager.ResourceType enum order:
# LOG=0, PLANK=1, APPLE=2, CIDER=3, WOOL=4, CLOTHES=5, CLAY=6, BRICK=7,
# COAL=8, IRON_ORE=9, IRON_BAR=10, TOOL=11, MILK=12, CHEESE=13,
# WHEAT=14, FLOUR=15, BREAD=16, BEER=17,
# RAW_FISH=18, SMOKED_FISH=19, FLAX=20, FLAX_CLOTHES=21
const _ICON_TEXTURE := {
    0: preload("res://Textures/Log.png"),
    1: preload("res://Textures/planks.png"),
    2: preload("res://Textures/apple.png"),
    3: preload("res://Textures/cider.png"),
    4: preload("res://Textures/Wool.png"),
    5: preload("res://Textures/Clothes.png"),
    6: preload("res://Textures/ore.png"),
    7: preload("res://Textures/brick.png"),
    8: preload("res://Textures/ore.png"),
    9: preload("res://Textures/ore.png"),
    10: preload("res://Textures/brick.png"),
    11: preload("res://Textures/tool.png"),
    12: preload("res://Textures/cider.png"),
    13: preload("res://Textures/cheese.png"),
    14: preload("res://Textures/wheat.png"),
    15: preload("res://Textures/flour.png.png"),
    16: preload("res://Textures/bread.png.png"),
    17: preload("res://Textures/cider.png"),
    18: preload("res://Textures/raw fish.png"),
    19: preload("res://Textures/smoked fish.png"),
    20: preload("res://Textures/flax.png"),
    21: preload("res://Textures/flax clothes.png"),
}

const _RESOURCE_NEED := {
    2: ["hunger", "apple_satisfaction"],
    3: ["thirst", "cider_satisfaction"],
    5: ["clothing", "clothes_satisfaction"],
    11: ["tools", "tool_satisfaction"],
    12: ["thirst", "milk_satisfaction"],
    13: ["hunger", "cheese_satisfaction"],
    16: ["hunger", "bread_satisfaction"],
    17: ["thirst", "beer_satisfaction"],
    19: ["hunger", "smoked_fish_satisfaction"],
    21: ["clothing", "flax_clothes_satisfaction"],
}

# Modulate to distinguish resources that share the same base texture
const _ICON_MODULATE := {
    6: Color(0.85, 0.58, 0.32), # CLAY — warm brown over ore.png
}

const _IronOreScene = preload("res://Scenes/Resources/IronOre/IronOre.tscn")
const _IronBarScene = preload("res://Scenes/Resources/IronBar/IronBar.tscn")
const _MilkScene = preload("res://Scenes/Resources/Milk/Milk.tscn")
const _CoalScene = preload("res://Scenes/Resources/Coal/Coal.tscn")
const _BeerScene = preload("res://Scenes/Resources/Beer/Beer.tscn")

var _icon_materials: Dictionary = {}

var _panel: PanelContainer
var _margin: MarginContainer
var _vbox: VBoxContainer
var _name_label: Label
var _cost_row: HBoxContainer
var _action_row: HBoxContainer
var _satisfy_row: HBoxContainer
var _warning_label: Label

func _ready() -> void:
    layer = 100

    var iron_ore := _IronOreScene.instantiate()
    _icon_materials[9] = iron_ore.get_node("Sprite2D").material as ShaderMaterial
    iron_ore.free()

    var iron_bar := _IronBarScene.instantiate()
    _icon_materials[10] = iron_bar.get_node("Sprite2D").material as ShaderMaterial
    iron_bar.free()

    var milk := _MilkScene.instantiate()
    _icon_materials[12] = milk.get_node("Sprite2D").material as ShaderMaterial
    milk.free()

    var coal := _CoalScene.instantiate()
    _icon_materials[8] = coal.get_node("Sprite2D").material as ShaderMaterial
    coal.free()

    var beer := _BeerScene.instantiate()
    _icon_materials[17] = beer.get_node("Sprite2D").material as ShaderMaterial
    beer.free()

    _panel = PanelContainer.new()
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_panel)

    _margin = MarginContainer.new()
    _panel.add_child(_margin)

    _vbox = VBoxContainer.new()
    _margin.add_child(_vbox)

    _name_label = Label.new()
    _vbox.add_child(_name_label)

    _cost_row = HBoxContainer.new()
    _vbox.add_child(_cost_row)

    _action_row = HBoxContainer.new()
    _vbox.add_child(_action_row)

    _satisfy_row = HBoxContainer.new()
    _vbox.add_child(_satisfy_row)

    _warning_label = Label.new()
    _warning_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1))
    _warning_label.add_theme_font_size_override("font_size", 13)
    _warning_label.visible = false
    _vbox.add_child(_warning_label)

    _panel.visible = false

func show_tooltip(data: Dictionary, show_cost: bool = true, warning: String = "") -> void:
    _populate(data, show_cost, warning)
    _panel.visible = true

func hide_tooltip() -> void:
    _panel.visible = false

func _process(_delta: float) -> void:
    if not _panel.visible:
        return

    var mouse := get_viewport().get_mouse_position()
    var vp_size := get_viewport().get_visible_rect().size

    # Use size if available, fallback to minimum size
    var sz := _panel.size
    if sz == Vector2.ZERO:
        sz = _panel.get_minimum_size()

    var margin_x := 12.0
    var margin_y := 8.0

    var x: float
    var y: float

    # --- Horizontal ---
    var space_right := vp_size.x - mouse.x
    var space_left := mouse.x

    if space_right >= sz.x + margin_x:
        # Enough room on the right
        x = mouse.x + margin_x
    elif space_left >= sz.x + margin_x:
        # Otherwise try left
        x = mouse.x - sz.x - margin_x
    else:
        # Neither fits fully → clamp
        x = clamp(mouse.x + margin_x, 0.0, vp_size.x - sz.x)

    # --- Vertical ---
    var space_above := mouse.y
    var space_below := vp_size.y - mouse.y

    if space_above >= sz.y + margin_y:
        # Prefer above
        y = mouse.y - sz.y - margin_y
    elif space_below >= sz.y + margin_y:
        # Otherwise below
        y = mouse.y + margin_y
    else:
        # Neither fits fully → clamp
        y = clamp(mouse.y - sz.y - margin_y, 0.0, vp_size.y - sz.y)

    _panel.position = Vector2(x, y)

func _populate(data: Dictionary, show_cost: bool, warning: String = "") -> void:
    var font_size := 14 if show_cost else 11
    var icon_size := 20 if show_cost else 14
    var pad := 8 if show_cost else 5
    var pad_v := 6 if show_cost else 4
    var sep := 4 if show_cost else 2

    _margin.add_theme_constant_override("margin_left", pad)
    _margin.add_theme_constant_override("margin_right", pad)
    _margin.add_theme_constant_override("margin_top", pad_v)
    _margin.add_theme_constant_override("margin_bottom", pad_v)
    _vbox.add_theme_constant_override("separation", sep)

    _name_label.text = data["display_name"]
    _name_label.add_theme_font_size_override("font_size", font_size)

    for c in _cost_row.get_children():
        c.queue_free()
    _cost_row.visible = show_cost
    _cost_row.add_theme_constant_override("separation", sep)
    if show_cost:
        if data["cost"] < 0:
            _add_label(_cost_row, "Cost: Free", font_size)
        else:
            _add_label(_cost_row, "Cost: ", font_size)
            _add_icon(_cost_row, data["cost"], icon_size)

    for c in _action_row.get_children():
        c.queue_free()
    _action_row.add_theme_constant_override("separation", sep)
    match data["action"]:
        "produce":
            _add_label(_action_row, "Produces ", font_size)
            for i in data["output"].size():
                if i > 0:
                    _add_label(_action_row, " + ", font_size)
                _add_icon(_action_row, data["output"][i], icon_size)
        "convert":
            _add_label(_action_row, "Converts ", font_size)
            for i in data["inputs"].size():
                if i > 0:
                    _add_label(_action_row, " + ", font_size)
                _add_icon(_action_row, data["inputs"][i], icon_size)
            _add_label(_action_row, " to ", font_size)
            for i in data["output"].size():
                if i > 0:
                    _add_label(_action_row, " + ", font_size)
                _add_icon(_action_row, data["output"][i], icon_size)
        "train":
            _add_label(_action_row, "Build buildings", font_size)

    for c in _satisfy_row.get_children():
        c.queue_free()
    _satisfy_row.add_theme_constant_override("separation", sep)
    var output: Array = data.get("output", [-1])
    if _RESOURCE_NEED.has(output[0]):
        var info: Array = _RESOURCE_NEED[output[0]]
        var sat: int = int(Constants.get(info[1]))
        _add_label(_satisfy_row, "Satisfies %d %s" % [sat, info[0]], font_size)
        _satisfy_row.visible = true
    else:
        _satisfy_row.visible = false

    _warning_label.text = warning
    _warning_label.visible = warning != ""

func _add_label(parent: HBoxContainer, text: String, font_size: int) -> void:
    var lbl := Label.new()
    lbl.text = text
    lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    lbl.add_theme_font_size_override("font_size", font_size)
    parent.add_child(lbl)

func _add_icon(parent: HBoxContainer, resource_type: int, icon_size: int) -> void:
    var tex_rect := TextureRect.new()
    tex_rect.texture = _ICON_TEXTURE.get(resource_type)
    tex_rect.custom_minimum_size = Vector2(icon_size, icon_size)
    tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    if _icon_materials.has(resource_type):
        tex_rect.material = _icon_materials[resource_type]
    elif _ICON_MODULATE.has(resource_type):
        tex_rect.modulate = _ICON_MODULATE[resource_type]
    parent.add_child(tex_rect)
