extends Node2D

@onready var _map: Map = $Map
@onready var camera: GameCamera = $Camera
@onready var _building_manager: BuildingManager = $BuildingManager
@onready var _coordination_manager: CoordinationManager = $CoordinationManager
@onready var _forest: Forest = $Forest

@onready var _game_over_ui: CanvasLayer = $GameOverUI
@onready var _game_won_ui: CanvasLayer = $GameWonUI

var _hud: HUD
var _hud_layer: CanvasLayer
var _tutorial: Tutorial
var _level_pixel_size: Vector2i
var _win_overlay: Control

func _on_game_over() -> void:
    _game_over_ui.visible = true

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    _game_over_ui.add_child(center)

    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.02, 0.02, 0.92)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    style.content_margin_left = 40.0
    style.content_margin_right = 40.0
    style.content_margin_top = 28.0
    style.content_margin_bottom = 28.0
    panel.add_theme_stylebox_override("panel", style)
    center.add_child(panel)

    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 16)
    panel.add_child(vbox)

    var title := Label.new()
    title.text = "GAME OVER"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 48)
    title.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2))
    vbox.add_child(title)

    var reason := Label.new()
    reason.text = "Your last builder has died."
    reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reason.add_theme_font_size_override("font_size", 22)
    reason.add_theme_color_override("font_color", Color(0.85, 0.75, 0.7))
    vbox.add_child(reason)

    var restart_btn := Button.new()
    restart_btn.text = "Restart"
    restart_btn.add_theme_font_size_override("font_size", 20)
    restart_btn.custom_minimum_size = Vector2(160, 44)
    restart_btn.pressed.connect(func(): get_tree().reload_current_scene())
    vbox.add_child(restart_btn)

func _on_game_won() -> void:
    _hud_layer.visible = false
    camera.zoom_out_to_map(_level_pixel_size, 2.5, func():
        await get_tree().create_timer(1.5).timeout
        _show_win_overlay()
    )

func _show_win_overlay() -> void:
    _game_won_ui.visible = true

    _win_overlay = CenterContainer.new()
    _win_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _win_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
    _game_won_ui.add_child(_win_overlay)

    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.08, 0.06, 0.04, 0.88)
    style.corner_radius_top_left = 12
    style.corner_radius_top_right = 12
    style.corner_radius_bottom_left = 12
    style.corner_radius_bottom_right = 12
    style.content_margin_left = 40.0
    style.content_margin_right = 40.0
    style.content_margin_top = 28.0
    style.content_margin_bottom = 28.0
    panel.add_theme_stylebox_override("panel", style)
    _win_overlay.add_child(panel)

    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 16)
    panel.add_child(vbox)

    var title := Label.new()
    title.text = "The town of Millville is flourishing..."
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 36)
    title.add_theme_color_override("font_color", Color.WHITE)
    vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Thanks for playing!"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 24)
    subtitle.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
    vbox.add_child(subtitle)

    var continue_btn := Button.new()
    continue_btn.text = "Continue Playing"
    continue_btn.add_theme_font_size_override("font_size", 20)
    continue_btn.custom_minimum_size = Vector2(200, 48)
    continue_btn.pressed.connect(_on_continue_playing)
    vbox.add_child(continue_btn)

    var tween := create_tween()
    tween.tween_property(_win_overlay, "modulate", Color.WHITE, 1.0)

func _on_continue_playing() -> void:
    var tween := create_tween()
    tween.tween_property(_win_overlay, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
    tween.tween_callback(func():
        _game_won_ui.visible = false
        camera.zoom_in_from_map(2.0, func():
            _hud_layer.visible = true
        )
    )

func _ready() -> void:
    var tile_size := _map.get_tile_size()
    _level_pixel_size = Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y)
    camera.setup(_level_pixel_size)
    _forest.setup(_map, self )
    _building_manager.setup(_map, _coordination_manager, _forest)
    _coordination_manager.game_over.connect(_on_game_over)
    _coordination_manager.game_won.connect(_on_game_won)

    _hud_layer = CanvasLayer.new()
    _hud_layer.layer = 10
    add_child(_hud_layer)
    _hud = preload("res://Scenes/HUD/HUD.tscn").instantiate() as HUD
    _hud.setup(_coordination_manager)
    _hud_layer.add_child(_hud)

    var msg_layer := CanvasLayer.new()
    msg_layer.layer = 20
    add_child(msg_layer)
    var message_system := MessageSystem.new()
    msg_layer.add_child(message_system)
    message_system.setup(_coordination_manager)

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
