class_name Tutorial
extends CanvasLayer

const _CLICK := "click"
const _EVENT := "event"
const _EVENT_AUTO := "event_auto"

var _steps: Array = []
var _step: int = 0
var _waiting_for_event: String = ""
var _auto_timer: float = -1.0
var _started: bool = false

var _overlay: TutorialOverlay
var _panel: PanelContainer
var _msg_label: Label
var _click_hint: Label

var _coordination_manager: CoordinationManager
var _building_manager: BuildingManager
var _hud: HUD
var _camera: Camera2D

func setup(cm: CoordinationManager, bm: BuildingManager, hud: HUD, cam: Camera2D) -> void:
    _coordination_manager = cm
    _building_manager = bm
    _hud = hud
    _camera = cam

func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    _build_ui()

func _build_ui() -> void:
    _overlay = TutorialOverlay.new()
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(_overlay)
    _overlay.gui_input.connect(_on_overlay_input)

    _panel = PanelContainer.new()
    _panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    _panel.offset_top = -150.0
    _panel.offset_bottom = -10.0
    _panel.offset_left = 80.0
    _panel.offset_right = -80.0
    _panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _panel.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_panel)

    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.04, 0.04, 0.1, 0.92)
    style.corner_radius_top_left = 8
    style.corner_radius_top_right = 8
    style.corner_radius_bottom_left = 8
    style.corner_radius_bottom_right = 8
    style.content_margin_left = 20.0
    style.content_margin_right = 20.0
    style.content_margin_top = 12.0
    style.content_margin_bottom = 12.0
    _panel.add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_theme_constant_override("separation", 6)
    _panel.add_child(vbox)

    _msg_label = Label.new()
    _msg_label.add_theme_font_size_override("font_size", 20)
    _msg_label.add_theme_color_override("font_color", Color.WHITE)
    _msg_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
    _msg_label.add_theme_constant_override("shadow_offset_x", 1)
    _msg_label.add_theme_constant_override("shadow_offset_y", 1)
    _msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_child(_msg_label)

    _click_hint = Label.new()
    _click_hint.text = "[ click to continue ]"
    _click_hint.add_theme_font_size_override("font_size", 11)
    _click_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
    _click_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _click_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    vbox.add_child(_click_hint)

func start() -> void:
    _build_steps()
    _step = 0
    _started = true
    _show_step()

func _build_steps() -> void:
    _steps = [
        _mc("Click to start."),
        _mc("Welcome to Logistictown!"),
        _mea("Use WASD, arrows, or middle mouse button to pan the map.", "panned", 2.0),
        _mc("Your goal is to reach a population of 50."),
        _mc("You currently have none.", func(): return _hud.get_workers_rect()),
        _me("Let's fix this by building a Builder Hut.", "builder_button_clicked",
            func(): return _building_manager.get_builder_button_rect()),
        _w("building_placed:BuilderHut"),
        _mc("Your first building is free, but others are not."),
        _mc("You have 2 planks.", func(): return _hud.get_planks_rect()),
        _me("Use them to secure plank production.", "woodcutter_or_sawmill_clicked",
            func(): return _building_manager.get_woodcutter_sawmill_rect()),
        _w("construction_queued"),
        _mc("You have 1 building site.", func(): return _hud.get_planks_rect()),
        _mc("Your builder will take a plank and go build it."),
        _w("worker_count:3"),
        _mc("You already have 3 people!"),
        _mc("But they have needs."),
        _mc("Without food and drink, workers will die."),
        _mc("Without clothes and tools, they will stop working."),
        _mc("You have some time before it happens."),
        _mc("Plan your town wisely!"),
        _w("hungry_worker"),
        _mc("You have a hungry worker!"),
        # Branch appended dynamically in _advance()
    ]

func _mc(text: String, highlight: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _CLICK, highlight = highlight}

func _me(text: String, event: String, highlight: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _EVENT, event = event, highlight = highlight}

func _mea(text: String, event: String, delay: float) -> Dictionary:
    return {type = "message", text = text, advance = _EVENT_AUTO, event = event, auto_delay = delay}

func _w(event: String) -> Dictionary:
    return {type = "wait", event = event}

func _show_step() -> void:
    if _step >= _steps.size():
        _finish()
        return
    var step: Dictionary = _steps[_step]
    if step.type == "wait":
        visible = false
        get_tree().paused = false
        _waiting_for_event = step.event
        return

    visible = true
    get_tree().paused = true
    _msg_label.text = step.text

    var hl: Callable = step.get("highlight", Callable())
    _overlay.has_highlight = hl.is_valid()
    if hl.is_valid():
        _overlay.highlight_rect = hl.call()
    _overlay.queue_redraw()

    var advance: String = step.get("advance", _CLICK)
    if advance == _CLICK:
        _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
        _click_hint.visible = true
    else:
        _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _click_hint.visible = false
        _waiting_for_event = step.get("event", "")

func _on_overlay_input(event: InputEvent) -> void:
    if not _started or _step >= _steps.size():
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if _steps[_step].get("advance", "") == _CLICK:
            _advance()

func on_event(event_name: String) -> void:
    if not _started or _waiting_for_event != event_name:
        return
    _waiting_for_event = ""
    var step: Dictionary = _steps[_step]
    if step.get("advance", "") == _EVENT_AUTO:
        _auto_timer = step.get("auto_delay", 1.0)
    else:
        _advance()

func _advance() -> void:
    _step += 1
    # After "You have a hungry worker!" — append branch steps based on food supply
    if _step == _steps.size():
        var stats := _coordination_manager.get_hud_stats()
        var food: int = (stats.resources as Dictionary).get(CoordinationManager.ResourceType.APPLE, 0) \
                      + (stats.resources as Dictionary).get(CoordinationManager.ResourceType.CHEESE, 0)
        if food > 0:
            _steps.append(_mc("But you also have %d food!" % food))
            _steps.append(_mc("The worker will go eat."))
        else:
            _steps.append(_mc("But you have no food!"))
            _steps.append(_mc("Build one of the food buildings!"))
    _show_step()

func _finish() -> void:
    visible = false
    get_tree().paused = false

func _process(delta: float) -> void:
    if not _started:
        return
    if _auto_timer > 0.0:
        _auto_timer -= delta
        if _auto_timer <= 0.0:
            _auto_timer = -1.0
            _advance()
    if visible and _step < _steps.size():
        var hl: Callable = _steps[_step].get("highlight", Callable())
        if hl.is_valid():
            _overlay.highlight_rect = hl.call()
            _overlay.queue_redraw()
