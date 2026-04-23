extends Node2D

@onready var _map: Map = $Map
@onready var camera: Camera2D = $Camera
@onready var _building_manager: BuildingManager = $BuildingManager
@onready var _coordination_manager: CoordinationManager = $CoordinationManager
@onready var _forest: Forest = $Forest

@onready var _game_over_ui: CanvasLayer = $GameOverUI
@onready var _game_won_ui: CanvasLayer = $GameWonUI

var _hud: HUD
var _tutorial: Tutorial

func _on_game_over() -> void:
    _game_over_ui.visible = true

func _on_game_won() -> void:
    _game_won_ui.visible = true

func _ready() -> void:
    var tile_size := _map.get_tile_size()
    camera.setup(Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y))
    _forest.setup(_map, self )
    _building_manager.setup(_map, _coordination_manager, _forest)
    _coordination_manager.game_over.connect(_on_game_over)
    _coordination_manager.game_won.connect(_on_game_won)

    var hud_layer := CanvasLayer.new()
    hud_layer.layer = 10
    add_child(hud_layer)
    _hud = HUD.new()
    _hud.setup(_coordination_manager)
    hud_layer.add_child(_hud)

    _tutorial = Tutorial.new()
    add_child(_tutorial)
    _tutorial.setup(_coordination_manager, _building_manager, _hud, camera)

    camera.panned.connect(func(): _tutorial.on_event("panned"))
    _building_manager.building_button_pressed.connect(func(key: String):
        if key == "BuilderHut":
            _tutorial.on_event("builder_button_clicked")
    )
    _building_manager.building_placed.connect(func(key: String):
        _tutorial.on_event("building_placed:" + key)
    )
    _building_manager.planks_dropdown_hovered.connect(func(): _tutorial.on_event("planks_hovered"))
    _building_manager.food_section_hovered.connect(func(): _tutorial.on_event("food_hovered"))
    _coordination_manager.worker_registered.connect(func(count: int):
        if count >= 3:
            _tutorial.on_event("worker_count:3")
    )

    _show_start_screen()

func _show_start_screen() -> void:
    var layer := CanvasLayer.new()
    layer.layer = 99
    layer.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(layer)

    var bg := ColorRect.new()
    bg.set_anchors_preset(Control.PRESET_FULL_RECT)
    bg.color = Color(0.08, 0.06, 0.05, 0.96)
    layer.add_child(bg)

    var vbox := VBoxContainer.new()
    vbox.anchor_left = 0.5
    vbox.anchor_top = 0.5
    vbox.anchor_right = 0.5
    vbox.anchor_bottom = 0.5
    vbox.offset_left = -200.0
    vbox.offset_right = 200.0
    vbox.offset_top = -100.0
    vbox.offset_bottom = 100.0
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 16)
    layer.add_child(vbox)

    var title := Label.new()
    title.text = "Millville"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 42)
    title.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(title)

    var tutorial_check := CheckBox.new()
    tutorial_check.text = "Enable Tutorial"
    tutorial_check.button_pressed = true
    tutorial_check.alignment = HORIZONTAL_ALIGNMENT_CENTER
    tutorial_check.add_theme_font_size_override("font_size", 18)
    tutorial_check.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(tutorial_check)

    var start_btn := Button.new()
    start_btn.text = "Start Game"
    start_btn.add_theme_font_size_override("font_size", 20)
    start_btn.custom_minimum_size = Vector2(160, 44)
    start_btn.pressed.connect(func():
        layer.queue_free()
        if tutorial_check.button_pressed:
            _tutorial.start()
    )
    vbox.add_child(start_btn)
