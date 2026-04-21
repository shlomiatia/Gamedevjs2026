class_name BuildingTooltipManager
extends Node

# All buildings share the same house.png sprite: 170x207, centered at y=-104
const _SPRITE_SIZE := Vector2(170, 207)
const _SPRITE_OFFSET_Y := -104.0
const _HOVER_DELAY := 1.0

# ResourceType integers: LOG=0 PLANK=1 APPLE=2 CIDER=3 WOOL=4 CLOTHES=5
#                        CLAY=6 BRICK=7 COAL=8 IRON_ORE=9 IRON_BAR=10 TOOL=11
const TOOLTIP_DATA := {
    "WoodcutterHut": {"display_name": "Woodcutter", "cost": 1, "action": "produce", "output": [0]},
    "BuilderHut": {"display_name": "Builder", "cost": 1, "action": "train"},
    "Sawmill": {"display_name": "Sawmill", "cost": 1, "action": "convert", "inputs": [0], "output": [1]},
    "AppleFarm": {"display_name": "Apple Farm", "cost": 1, "action": "produce", "output": [2]},
    "CiderMill": {"display_name": "Cider Mill", "cost": 1, "action": "convert", "inputs": [2], "output": [3]},
    "SheepFarm": {"display_name": "Sheep Farm", "cost": 1, "action": "produce", "output": [12, 4]},
    "WoolMill": {"display_name": "Wool Mill", "cost": 1, "action": "convert", "inputs": [4], "output": [5]},
    "ClayPit": {"display_name": "Clay Pit", "cost": 1, "action": "produce", "output": 6},
    "ClayKiln": {"display_name": "Clay Kiln", "cost": 7, "action": "convert", "inputs": [6, 0], "output": 7},
    "CoalMine": {"display_name": "Coal Mine", "cost": 1, "action": "produce", "output": [8]},
    "IronMine": {"display_name": "Iron Mine", "cost": 1, "action": "produce", "output": [9]},
    "SteelMill": {"display_name": "Steel Mill", "cost": 7, "action": "convert", "inputs": [9, 8], "output": [10]},
    "Toolsmith": {"display_name": "Toolsmith", "cost": 7, "action": "convert", "inputs": [8, 10], "output": [11]},
    "Fromage": {"display_name": "Fromage", "cost": 7, "action": "convert", "inputs": [12, 0], "output": [13]},
    "WheatFarm": {"display_name": "Wheat Farm", "cost": 1, "action": "produce", "output": [14]},
    "Gritsmill": {"display_name": "Flour Mill", "cost": 1, "action": "convert", "inputs": [14], "output": [15]},
    "Bakery": {"display_name": "Bakery", "cost": 7, "action": "convert", "inputs": [15, 0], "output": [16]},
    "Brewery": {"display_name": "Brewery", "cost": 7, "action": "convert", "inputs": [14, 0], "output": [17]},
}

var _tooltip: BuildingTooltip
var _hovered: Array = [] # Array of {building: Node2D, key: String}
var _hover_timer: float = 0.0
var _tooltip_shown: bool = false
var _btn_hide_pending: bool = false

func _ready() -> void:
    _tooltip = BuildingTooltip.new()
    add_child(_tooltip)

func connect_button(button: Button, key: String) -> void:
    button.mouse_entered.connect(func():
        _btn_hide_pending = false
        _cancel_hover()
        _tooltip.show_tooltip(TOOLTIP_DATA[key])
    )
    button.mouse_exited.connect(func():
        _btn_hide_pending = true
        get_tree().create_timer(0.12).timeout.connect(func():
            if _btn_hide_pending:
                _btn_hide_pending = false
                _tooltip.hide_tooltip()
        )
    )

func connect_builder_button(button: Button) -> void:
    button.mouse_entered.connect(func():
        _btn_hide_pending = false
        _cancel_hover()
        var data: Dictionary = TOOLTIP_DATA["BuilderHut"].duplicate()
        if BuilderHut._placed_count == 0:
            data["cost"] = -1
        _tooltip.show_tooltip(data)
    )
    button.mouse_exited.connect(func():
        _btn_hide_pending = true
        get_tree().create_timer(0.12).timeout.connect(func():
            if _btn_hide_pending:
                _btn_hide_pending = false
                _tooltip.hide_tooltip()
        )
    )

func attach_to_building(building: Node2D, key: String) -> void:
    var area := Area2D.new()
    area.input_pickable = true
    var col := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = _SPRITE_SIZE
    col.shape = rect
    area.add_child(col)
    area.position = Vector2(0.0, _SPRITE_OFFSET_Y)
    area.mouse_entered.connect(func(): _on_hover_start(building, key))
    area.mouse_exited.connect(func(): _on_hover_end(building))
    building.add_child(area)

func _on_hover_start(building: Node2D, key: String) -> void:
    _hovered.append({"building": building, "key": key})
    _hover_timer = 0.0
    _tooltip_shown = false
    _tooltip.hide_tooltip()

func _on_hover_end(building: Node2D) -> void:
    _hovered = _hovered.filter(func(h): return h["building"] != building)
    _hover_timer = 0.0
    _tooltip_shown = false
    _tooltip.hide_tooltip()

func _cancel_hover() -> void:
    _hovered.clear()
    _hover_timer = 0.0
    _tooltip_shown = false

func _process(delta: float) -> void:
    if _hovered.is_empty() or _tooltip_shown:
        return
    _hover_timer += delta
    if _hover_timer < _HOVER_DELAY:
        return
    _tooltip_shown = true
    # Highest Y = lowest on screen = closest to player — takes priority
    var best: Dictionary = _hovered[0]
    for h in _hovered:
        if (h["building"] as Node2D).position.y > (best["building"] as Node2D).position.y:
            best = h
    _tooltip.show_tooltip(TOOLTIP_DATA[best["key"]], false)
