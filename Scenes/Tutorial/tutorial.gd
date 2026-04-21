class_name Tutorial
extends CanvasLayer

const _CLICK := "click"
const _EVENT := "event"
const WAIT_STEP_DELAY := 0.

var _steps: Array = []
var _step: int = 0
var _waiting_for_event: String = ""
var _auto_timer: float = -1.0
var _started: bool = false

var _overlay: TutorialOverlay
var _msg_label: Label

var _branch_appended: bool = false

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
    _msg_label.add_theme_font_size_override("font_size", 24)
    _msg_label.add_theme_color_override("font_color", Color.WHITE)
    _msg_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
    _msg_label.add_theme_constant_override("shadow_offset_x", 2)
    _msg_label.add_theme_constant_override("shadow_offset_y", 2)
    _msg_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_msg_label)

func start() -> void:
    _build_steps()
    _step = 0
    _started = true
    _show_step()

func _build_steps() -> void:
    _steps = [
        _mc("Welcome to Logistictown!"),
        _me("Use WASD, arrows, or middle mouse button to pan the map.", "panned"),
        _mc("Your goal is to reach a population of 50."),
        _mc("You currently have none.", func(): return _hud.get_workers_rect()),
        _meu("Let's fix this by building a Builder Hut.", "builder_button_clicked",
            func(): return _building_manager.get_builder_button_rect()),
        _w("building_placed:BuilderHut"),
        _mc("Your first building is free, but others are not."),
        _mc("You have 2 planks.", func(): return _hud.get_planks_rect()),
        _meu("Use them to secure plank production.", "woodcutter_or_sawmill_clicked",
            func(): return _building_manager.get_woodcutter_sawmill_rect()),
        _w("construction_queued"),
        _mc("You have 1 building site.", func(): return _hud.get_planks_rect()),
        _mc("Your builder will take a plank and go build it."),
        _w("worker_count:3"),
        _mc("You already have 3 people!", func(): return _hud.get_workers_rect()),
        _mc("But they have needs."),
        _mc("Without food and drink, workers will die.", func(): return _hud.get_food_drink_rect()),
        _mc("Without clothes and tools, they will stop working.", func(): return _hud.get_clothing_tool_rect()),
        _mc("You have some time before it happens."),
        _mc("Plan your town wisely!"),
        _w("hungry_worker"),
        _mc("You have a hungry worker!"),
        # Branch appended dynamically in _advance()
    ]

# Click to continue
func _mc(text: String, highlight: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _CLICK, highlight = highlight}

# Event advance — blocks UI input (e.g. pan the camera)
func _me(text: String, event: String, highlight: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _EVENT, event = event, highlight = highlight, pass_input = false}

# Event advance — allows UI input so player can click a button
func _meu(text: String, event: String, highlight: Callable = Callable()) -> Dictionary:
    return {type = "message", text = text, advance = _EVENT, event = event, highlight = highlight, pass_input = true}

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
            call_deferred("_advance")
    # Block everything else from reaching the game
    get_viewport().set_input_as_handled()

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

    if step.get("advance", "") == _EVENT:
        _waiting_for_event = step.get("event", "")

func on_event(event_name: String) -> void:
    if not _started or _waiting_for_event != event_name:
        return
    _waiting_for_event = ""
    if _step < _steps.size() and _steps[_step].type == "wait":
        _auto_timer = WAIT_STEP_DELAY
    else:
        # Message step — immediately dismiss overlay
        _advance()

func _advance() -> void:
    _step += 1
    if not _branch_appended and _step == _steps.size():
        _branch_appended = true
        var cm := _coordination_manager
        var food := 0
        for rt in [CoordinationManager.ResourceType.APPLE, CoordinationManager.ResourceType.CHEESE]:
            for building in cm.buildings:
                var pile: ResourcePile = building.get_pile_for_type(rt)
                if pile != null:
                    food += pile.get_child_count()
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
