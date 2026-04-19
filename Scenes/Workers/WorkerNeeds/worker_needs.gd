class_name WorkerNeeds
extends Node2D

signal needs_satisfied
signal died

const FONT_SIZE := 9
const NUM_Y := -72.0
const NAME_Y := NUM_Y - (FONT_SIZE + 2) * 2 - 2

var hunger := 0.0
var thirst := 0.0
var clothing := 0.0
var _tool := 0.0

var _blocked_by_needs: Dictionary = {}

var _mover: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _navigator: WorkerNavigator = null
var _is_working := false
var _is_dead := false
var _need_requested: Dictionary = {}
var _active_needs: Array = []

func setup(mover: Node2D, map: Map, coordination_manager: Node, navigator: WorkerNavigator) -> void:
    _mover = mover
    _map = map
    _coordination_manager = coordination_manager
    _navigator = navigator
    hunger = Constants.initial_hunger
    thirst = Constants.initial_thirst
    clothing = Constants.initial_clothing
    _tool = Constants.initial_tool

func set_working(val: bool) -> void:
    _is_working = val

func is_satisfying_need() -> bool:
    return not _active_needs.is_empty() or not _blocked_by_needs.is_empty()

func get_need_value(need: int) -> float:
    match need:
        Worker.NeedType.FOOD: return hunger
        Worker.NeedType.DRINK: return thirst
        Worker.NeedType.CLOTHING: return clothing
        Worker.NeedType.TOOL: return _tool
    return INF

func handle_need(need: int, pile: ResourcePile) -> void:
    assert(need != Worker.NO_NEED, "handle_need called with NO_NEED")
    _receive_need(need, pile)

func _receive_need(need: int, pile: ResourcePile) -> void:
    for entry in _active_needs:
        if entry.need == need:
            return

    var new_val := get_need_value(need)
    var insert_at := _active_needs.size()
    for i in _active_needs.size():
        if get_need_value(_active_needs[i].need) > new_val:
            insert_at = i
            break
    _active_needs.insert(insert_at, {need = need, pile = pile})

    if insert_at == 0:
        _navigator.navigate_to(pile.global_position)

func _finish_need_trip() -> void:
    var entry: Dictionary = _active_needs[0]
    assert(is_instance_valid(entry.pile), "need pile is no longer valid")
    var resource: Node2D = (entry.pile as ResourcePile).collect(_mover)
    resource.queue_free()
    var satisfaction: float = Constants.need_satisfaction_value
    match entry.need:
        Worker.NeedType.FOOD: hunger = minf(Constants.initial_hunger, hunger + satisfaction)
        Worker.NeedType.DRINK: thirst = minf(Constants.initial_thirst, thirst + satisfaction)
        Worker.NeedType.CLOTHING: clothing = minf(Constants.initial_clothing, clothing + satisfaction)
        Worker.NeedType.TOOL: _tool = minf(Constants.initial_tool, _tool + satisfaction)
    _blocked_by_needs.erase(entry.need)
    _need_requested[entry.need] = false
    _active_needs.remove_at(0)

    if not _active_needs.is_empty():
        _navigator.navigate_to(_active_needs[0].pile.global_position)
    elif _blocked_by_needs.is_empty():
        needs_satisfied.emit()

func _process(delta: float) -> void:
    if _is_dead:
        return

    var is_working := _is_working && !is_satisfying_need()

    var hunger_drain := 2.0 if _navigator.is_moving() else 1.0
    hunger = maxf(0.0, hunger - hunger_drain * delta)
    var thirst_drain := 2.0 if is_working else 1.0
    thirst = maxf(0.0, thirst - thirst_drain * delta)
    clothing = maxf(0.0, clothing - 1.0 * delta)
    if is_working:
        _tool = maxf(0.0, _tool - 2.0 * delta)

    if hunger == 0.0 or thirst == 0.0:
        _is_dead = true
        died.emit()
        return

    if _coordination_manager != null:
        if not _need_requested.get(Worker.NeedType.FOOD, false) and hunger < Constants.hunger_threshold:
            _need_requested[Worker.NeedType.FOOD] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.FOOD)
        if not _need_requested.get(Worker.NeedType.DRINK, false) and thirst < Constants.thirst_threshold:
            _need_requested[Worker.NeedType.DRINK] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.DRINK)
        if not _need_requested.get(Worker.NeedType.CLOTHING, false) and clothing == 0.0:
            _need_requested[Worker.NeedType.CLOTHING] = true
            _blocked_by_needs[Worker.NeedType.CLOTHING] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.CLOTHING)
        if not _need_requested.get(Worker.NeedType.TOOL, false) and _tool == 0.0:
            _need_requested[Worker.NeedType.TOOL] = true
            _blocked_by_needs[Worker.NeedType.TOOL] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.TOOL)

    if not _active_needs.is_empty():
        if _navigator.tick(delta):
            _finish_need_trip()

    queue_redraw()

func _need_color(ratio: float, high: Color, mid: Color, low: Color) -> Color:
    return high if ratio > 0.5 else (mid if ratio > 0.25 else low)

func _ds(font: Font, pos: Vector2, text: String, width: int, color: Color) -> void:
    draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, 2, Color.BLACK)
    draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, color)

func _draw() -> void:
    var font := ThemeDB.fallback_font
    var col_w := 16
    var x0 := -col_w

    if _mover != null:
        _ds(font, Vector2(x0, NAME_Y), _mover.name, 64, Color.WHITE)

    var hr := hunger / Constants.initial_hunger
    _ds(font, Vector2(x0, NUM_Y), "%d" % int(hunger), col_w,
        _need_color(hr, Color(0.25, 0.8, 0.25), Color(0.9, 0.7, 0.1), Color(0.9, 0.2, 0.2)))

    var tr_ratio := thirst / Constants.initial_thirst
    _ds(font, Vector2(x0 + col_w, NUM_Y), "%d" % int(thirst), col_w,
        _need_color(tr_ratio, Color(0.2, 0.6, 0.9), Color(0.9, 0.8, 0.2), Color(0.9, 0.3, 0.1)))

    var cr := clothing / Constants.initial_clothing
    _ds(font, Vector2(x0, NUM_Y - FONT_SIZE - 2), "%d" % int(clothing), col_w,
        _need_color(cr, Color(0.7, 0.3, 0.9), Color(0.9, 0.7, 0.1), Color(0.9, 0.2, 0.2)))

    var tool_r := _tool / Constants.initial_tool
    _ds(font, Vector2(x0 + col_w, NUM_Y - FONT_SIZE - 2), "%d" % int(_tool), col_w,
        _need_color(tool_r, Color(0.8, 0.6, 0.2), Color(0.9, 0.7, 0.1), Color(0.9, 0.2, 0.2)))
