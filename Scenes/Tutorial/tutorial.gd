class_name Tutorial
extends CanvasLayer

const _CLICK := "click"
const _EVENT := "event"
const WAIT_STEP_DELAY := 0.

var _steps: Array = []
var _step: int = 0
var _waiting_for_event: String = ""
var _buffered_event: String = ""
var _auto_timer: float = -1.0
var _started: bool = false

var _overlay: TutorialOverlay
var _msg_label: Label
var _hover_detector: Control = null
var _click_player: AudioStreamPlayer = null

var _coordination_manager: CoordinationManager
var _building_manager: BuildingManager
var _hud: HUD
var _camera: Camera2D

func setup(cm: CoordinationManager, bm: BuildingManager, hud: HUD, cam: Camera2D) -> void:
    _coordination_manager = cm
    _building_manager = bm
    _hud = hud
    _camera = cam
    _build_steps()

func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = false
    _build_ui()

func _build_ui() -> void:
    _overlay = TutorialOverlay.new()
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.process_mode = Node.PROCESS_MODE_ALWAYS
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_overlay)

    _msg_label = Label.new()
    _msg_label.anchor_left = 0.5
    _msg_label.anchor_top = 0.5
    _msg_label.anchor_right = 0.5
    _msg_label.anchor_bottom = 0.5
    _msg_label.offset_left = -420.0
    _msg_label.offset_right = 420.0
    _msg_label.offset_top = -80.0
    _msg_label.offset_bottom = 80.0
    _msg_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _msg_label.grow_vertical = Control.GROW_DIRECTION_BOTH
    _msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _msg_label.label_settings = preload("res://Themes/label_medium.tres")
    _msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_msg_label)

    _click_player = AudioStreamPlayer.new()
    _click_player.stream = load("res://Audio/click.mp3")
    _click_player.process_mode = Node.PROCESS_MODE_ALWAYS
    add_child(_click_player)

func start() -> void:
    _step = 0
    _started = true
    _show_step()

func _build_steps() -> void:
    _steps = [
        _mc("Welcome to Millville!"),
        _me("Use WASD, arrows, or middle mouse button to pan the map.", "panned", Callable(), 1.0, true),
        _mc("Your goal is to reach a population of 30."),
        _mc("You currently have none.", func(): return _hud.get_workers_rect()),
        _meu("Let's fix this by building a Builder Hut.", "builder_button_clicked",
            func(): return _building_manager.get_builder_button_rect()),
        _w("building_placed:BuilderHut"),
        _mc("Your first building is free, but others are not."),
        _mc("You have 2 planks.", func(): return _hud.get_planks_rect()),
        _meu("Use them to secure plank production.\nBuild a woodcutter and a sawmill.", "planks_hovered",
            func(): return _building_manager.get_woodcutter_sawmill_rect()),
        _w("worker_count:3"),
        _mc("You already have 3 workers!", func(): return _hud.get_workers_rect()),
        _mc("But remember, they have needs."),
        _mc("Without food and drink, your workers will die.", func(): return _hud.get_food_drink_rect()),
        _mc("Without clothes and tools, they will stop working.", func(): return _hud.get_clothing_tool_rect()),
        _mc("You have some time before it happens."),
        _meu("Start food production early, and good luck!", "food_hovered",
            func(): return _building_manager.get_food_section_rect(),
            0.0, func(): return _building_manager.get_food_section_rect()),
    ]

# Click to continue
func _mc(text: String, highlight: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _CLICK, highlight = highlight}

# Event advance — blocks UI input (e.g. pan the camera); buffered=true allows the event to be caught before this step is reached
func _me(text: String, event: String, highlight: Callable = Callable(), delay: float = 0.0, buffered: bool = false) -> Dictionary:
    return {type = "message", text = text, advance = _EVENT, event = event, highlight = highlight, pass_input = false, delay = delay, buffered = buffered}

# Event advance — allows UI input so player can click a button
func _meu(text: String, event: String, highlight: Callable = Callable(), delay: float = 0.0, hover_area: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _EVENT, event = event, highlight = highlight, pass_input = true, delay = delay, hover_area = hover_area}

func _w(event: String) -> Dictionary:
    return {type = "wait", event = event}

func _input(event: InputEvent) -> void:
    if not _started or not visible:
        return
    # Always let middle mouse and motion through so camera panning works
    if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_MIDDLE:
        return
    if event is InputEventMouseMotion:
        return
    # During button-click steps, let all mouse input through to reach the buttons
    if _step < _steps.size():
        var step: Dictionary = _steps[_step]
        if step.get("advance", "") == _EVENT and step.get("pass_input", false):
            return
    # Left click advances click-type steps
    if event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
            and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
        if _step < _steps.size() and _steps[_step].get("advance", "") == _CLICK:
            if _click_player:
                _click_player.play()
            call_deferred("_advance")
    # Block everything else from reaching the game
    get_viewport().set_input_as_handled()

func _setup_hover_detector(rect: Rect2, event_name: String) -> void:
    _hover_detector = Control.new()
    _hover_detector.process_mode = Node.PROCESS_MODE_ALWAYS
    _hover_detector.position = rect.position
    _hover_detector.size = rect.size
    _hover_detector.mouse_filter = Control.MOUSE_FILTER_STOP
    _hover_detector.mouse_entered.connect(func(): on_event(event_name))
    add_child(_hover_detector)

func _clear_hover_detector() -> void:
    if _hover_detector:
        _hover_detector.queue_free()
        _hover_detector = null

func _show_step() -> void:
    _clear_hover_detector()
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

    if step.get("advance", "") == _EVENT:
        _waiting_for_event = step.get("event", "")
        if step.get("buffered", false) and _buffered_event == _waiting_for_event:
            _buffered_event = ""
            _trigger_event_advance()
            return
        var hover_area: Callable = step.get("hover_area", Callable())
        if hover_area.is_valid():
            _setup_hover_detector(hover_area.call(), step.event)

func on_event(event_name: String) -> void:
    if not _started:
        var next := _find_next_buffered_event()
        if next == event_name:
            _buffered_event = event_name
        return
    if _waiting_for_event != event_name:
        # Only buffer if the upcoming step marked itself as buffered
        var next := _find_next_buffered_event()
        if next == event_name:
            _buffered_event = event_name
        return
    _waiting_for_event = ""
    _trigger_event_advance()

func _find_next_buffered_event() -> String:
    for i in range(_step, _steps.size()):
        var s: Dictionary = _steps[i]
        if s.type == "wait":
            break
        if s.get("buffered", false):
            return s.get("event", "")
    return ""

func _trigger_event_advance() -> void:
    var delay: float = _steps[_step].get("delay", 0.0) if _step < _steps.size() else 0.0
    if delay > 0.0:
        _auto_timer = delay
    elif _step < _steps.size() and _steps[_step].type == "wait":
        _auto_timer = WAIT_STEP_DELAY
    else:
        _advance()

func _advance() -> void:
    _step += 1
    _show_step()

func _finish() -> void:
    visible = false
    get_tree().paused = false

func _process(delta: float) -> void:
    if not _started:
        return
    if _auto_timer >= 0.0:
        _auto_timer -= delta
        if _auto_timer <= 0.0:
            _auto_timer = -1.0
            _advance()
    if visible and _step < _steps.size():
        var hl: Callable = _steps[_step].get("highlight", Callable())
        if hl.is_valid():
            _overlay.highlight_rect = hl.call()
            _overlay.queue_redraw()
