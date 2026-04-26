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
var _click_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer

func _on_game_over() -> void:
    BuilderHut._placed_count = 0
    _game_over_ui.visible = true

    var center := CenterContainer.new()
    center.set_anchors_preset(Control.PRESET_FULL_RECT)
    _game_over_ui.add_child(center)

    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.05, 0.02, 0.02, 0.4)
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
    title.text = "Game over"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var red_title_settings := (preload("res://Themes/label_title.tres") as LabelSettings).duplicate()
    red_title_settings.font_color = Color(0.9, 0.2, 0.2)
    title.label_settings = red_title_settings
    vbox.add_child(title)

    var reason := Label.new()
    reason.text = "Your last builder has died."
    reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reason.label_settings = preload("res://Themes/label_medium.tres")
    vbox.add_child(reason)

    var restart_btn := Button.new()
    restart_btn.text = "Restart"
    restart_btn.add_theme_font_size_override("font_size", 20)
    restart_btn.custom_minimum_size = Vector2(160, 44)
    restart_btn.pressed.connect(func():
        _click_player.play()
        get_tree().reload_current_scene()
    )
    vbox.add_child(restart_btn)

func _on_game_won() -> void:
    _hud_layer.visible = false
    _building_manager.set_ui_visible(false)
    camera.zoom_out_to_map(_level_pixel_size, 2.5, func():
        await get_tree().create_timer(1.5).timeout
        _show_win_overlay()
    )

func _show_win_overlay() -> void:
    _game_won_ui.visible = true

    _win_overlay = Control.new()
    _win_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _win_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _win_overlay.modulate = Color(1.0, 1.0, 1.0, 0.0)
    _game_won_ui.add_child(_win_overlay)

    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color.TRANSPARENT
    panel.add_theme_stylebox_override("panel", style)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.0
    panel.anchor_bottom = 0.0
    panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
    panel.grow_vertical = Control.GROW_DIRECTION_END
    panel.offset_top = 20.0
    _win_overlay.add_child(panel)

    var vbox := VBoxContainer.new()
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 16)
    panel.add_child(vbox)

    var title := Label.new()
    title.text = "The town of Millville is thriving..."
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.label_settings = preload("res://Themes/label_title.tres")
    vbox.add_child(title)

    var subtitle := Label.new()
    subtitle.text = "Thanks for playing!"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.label_settings = preload("res://Themes/label_medium.tres")
    vbox.add_child(subtitle)

    var continue_btn := Button.new()
    continue_btn.text = "Continue playing"
    continue_btn.add_theme_font_size_override("font_size", 20)
    continue_btn.custom_minimum_size = Vector2(200, 48)
    continue_btn.pressed.connect(_on_continue_playing)
    vbox.add_child(continue_btn)

    var tween := create_tween()
    tween.tween_property(_win_overlay, "modulate", Color.WHITE, 1.0)

func _on_continue_playing() -> void:
    _click_player.play()
    var tween := create_tween()
    tween.tween_property(_win_overlay, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.5)
    tween.tween_callback(func():
        _game_won_ui.visible = false
        camera.zoom_in_from_map(2.0, func():
            _hud_layer.visible = true
            _building_manager.set_ui_visible(true)
        )
    )

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
        _coordination_manager.debug_dump()

func _on_connected(_payload):
        print("Playing as: ", WavedashSdk.get_username())

func _ready() -> void:
    WavedashSdk.backend_connected.connect(_on_connected)
    WavedashSdk.init({"debug": true})
    
    _click_player = AudioStreamPlayer.new()
    _click_player.stream = load("res://Audio/click.wav") as AudioStream
    add_child(_click_player)
    _music_player = AudioStreamPlayer.new()
    _music_player.stream = load("res://Audio/music.mp3") as AudioStream
    add_child(_music_player)

    var game_theme := Theme.new()
    game_theme.set_color("font_color", "Button", Color.WHITE)
    game_theme.set_color("font_hover_color", "Button", Color.WHITE)
    game_theme.set_color("font_pressed_color", "Button", Color(0.9, 0.9, 0.9))
    game_theme.set_color("font_disabled_color", "Button", Color(0.6, 0.6, 0.6, 0.5))
    game_theme.set_color("font_focus_color", "Button", Color.WHITE)
    game_theme.set_color("font_hover_pressed_color", "Button", Color.WHITE)
    game_theme.set_color("font_color", "CheckBox", Color.WHITE)
    game_theme.set_color("font_hover_color", "CheckBox", Color.WHITE)
    game_theme.set_color("font_focus_color", "CheckBox", Color.WHITE)
    game_theme.set_color("font_color", "TooltipLabel", Color.WHITE)
    var tooltip_style := StyleBoxFlat.new()
    tooltip_style.bg_color = Color(0.08, 0.06, 0.05, 0.92)
    tooltip_style.corner_radius_top_left = 4
    tooltip_style.corner_radius_top_right = 4
    tooltip_style.corner_radius_bottom_left = 4
    tooltip_style.corner_radius_bottom_right = 4
    tooltip_style.content_margin_left = 6
    tooltip_style.content_margin_top = 4
    tooltip_style.content_margin_right = 6
    tooltip_style.content_margin_bottom = 4
    game_theme.set_stylebox("panel", "TooltipPanel", tooltip_style)
    get_window().theme = game_theme

    var tile_size := _map.get_tile_size()
    _level_pixel_size = Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y)
    var scenic_top_px := (Map.RIVER_ROW - 4) * tile_size.y
    camera.setup(_level_pixel_size, scenic_top_px)
    _forest.setup(_map, self )
    _building_manager.setup(_map, _coordination_manager, _forest)
    _building_manager.set_ui_visible(false)
    _coordination_manager.game_over.connect(_on_game_over)
    _coordination_manager.game_won.connect(_on_game_won)
    _coordination_manager.building_completed.connect(func(count: int):
        if count == 4:
            _music_player.play()
    )

    _hud_layer = CanvasLayer.new()
    _hud_layer.layer = 10
    _hud_layer.visible = false
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
    bg.color = Color(0.08, 0.06, 0.05, 0.4)
    layer.add_child(bg)

    var vbox := VBoxContainer.new()
    vbox.anchor_left = 0.5
    vbox.anchor_top = 0.5
    vbox.anchor_right = 0.5
    vbox.anchor_bottom = 0.5
    vbox.offset_left = -220.0
    vbox.offset_right = 220.0
    vbox.offset_top = -210.0
    vbox.offset_bottom = 220.0
    vbox.alignment = BoxContainer.ALIGNMENT_CENTER
    vbox.add_theme_constant_override("separation", 0)
    layer.add_child(vbox)

    var title := Label.new()
    title.text = "Millville"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.label_settings = preload("res://Themes/label_title.tres")
    vbox.add_child(title)

    var tutorial_check := CheckBox.new()
    tutorial_check.text = "Enable tutorial"
    tutorial_check.focus_mode = Control.FOCUS_NONE
    tutorial_check.button_pressed = true
    tutorial_check.alignment = HORIZONTAL_ALIGNMENT_CENTER
    tutorial_check.add_theme_font_size_override("font_size", 20)
    tutorial_check.add_theme_color_override("font_color", Color.WHITE)
    tutorial_check.pressed.connect(func(): _click_player.play())
    vbox.add_child(tutorial_check)

    var start_btn := Button.new()
    start_btn.text = "Start game"
    start_btn.add_theme_font_size_override("font_size", 20)
    start_btn.custom_minimum_size = Vector2(160, 44)
    start_btn.pressed.connect(func():
        _click_player.play()
        layer.queue_free()
        _hud_layer.visible = true
        _building_manager.set_ui_visible(true)
        if tutorial_check.button_pressed:
            _tutorial.start()
    )
    vbox.add_child(start_btn)

    var mill_rect := TextureRect.new()
    mill_rect.texture = load("res://Textures/watermill.png") as Texture2D
    mill_rect.custom_minimum_size = Vector2(96 * 4, 96 * 4)
    mill_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    mill_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    mill_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    mill_rect.pivot_offset = Vector2(48 * 4, 48 * 4)
    mill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_child(mill_rect)

    var mill_tween := layer.create_tween().set_loops()
    mill_tween.tween_property(mill_rect, "rotation_degrees", 360.0, 6.0).set_trans(Tween.TRANS_LINEAR).as_relative()
