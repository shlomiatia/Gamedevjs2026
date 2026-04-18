class_name WorkerNeeds
extends Node2D

signal needs_satisfied
signal died

const BAR_WIDTH := 32.0
const BAR_HEIGHT := 4.0
const BAR_Y := -68.0
const THIRST_BAR_Y := BAR_Y - BAR_HEIGHT - 2.0
const CLOTHING_BAR_Y := THIRST_BAR_Y - BAR_HEIGHT - 2.0
const TOOL_BAR_Y := CLOTHING_BAR_Y - BAR_HEIGHT - 2.0
const DEBUG_FONT_SIZE := 9

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

    var hunger_drain := Constants.hunger_drain_working if _is_working else Constants.hunger_drain_normal
    hunger = maxf(0.0, hunger - hunger_drain * delta)
    var thirst_drain := Constants.thirst_drain_walking if _navigator.is_moving() else Constants.thirst_drain_normal
    thirst = maxf(0.0, thirst - thirst_drain * delta)
    clothing = maxf(0.0, clothing - Constants.clothing_drain * delta)
    if _is_working:
        _tool = maxf(0.0, _tool - Constants.tool_drain * 2.0 * delta)

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

func _draw() -> void:
    var bx := -BAR_WIDTH * 0.5
    draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
    draw_rect(Rect2(bx, THIRST_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
    draw_rect(Rect2(bx, CLOTHING_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
    draw_rect(Rect2(bx, TOOL_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))

    var hr := hunger / Constants.initial_hunger
    if hr > 0.0:
        var hc := Color(0.25, 0.8, 0.25) if hr > 0.5 else (Color(0.9, 0.7, 0.1) if hr > 0.25 else Color(0.9, 0.2, 0.2))
        draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH * hr, BAR_HEIGHT), hc)

    var tr_ratio := thirst / Constants.initial_thirst
    if tr_ratio > 0.0:
        var tc := Color(0.2, 0.6, 0.9) if tr_ratio > 0.5 else (Color(0.9, 0.8, 0.2) if tr_ratio > 0.25 else Color(0.9, 0.3, 0.1))
        draw_rect(Rect2(bx, THIRST_BAR_Y, BAR_WIDTH * tr_ratio, BAR_HEIGHT), tc)

    var cr := clothing / Constants.initial_clothing
    if cr > 0.0:
        var cc := Color(0.7, 0.3, 0.9) if cr > 0.5 else (Color(0.9, 0.7, 0.1) if cr > 0.25 else Color(0.9, 0.2, 0.2))
        draw_rect(Rect2(bx, CLOTHING_BAR_Y, BAR_WIDTH * cr, BAR_HEIGHT), cc)

    var tool_r := _tool / Constants.initial_tool
    if tool_r > 0.0:
        var tc2 := Color(0.8, 0.6, 0.2) if tool_r > 0.5 else (Color(0.9, 0.7, 0.1) if tool_r > 0.25 else Color(0.9, 0.2, 0.2))
        draw_rect(Rect2(bx, TOOL_BAR_Y, BAR_WIDTH * tool_r, BAR_HEIGHT), tc2)

    if _mover == null:
        return
    var font := ThemeDB.fallback_font
    var line_h := DEBUG_FONT_SIZE + 2.0

    var name_y := TOOL_BAR_Y - 2.0
    draw_string(font, Vector2(bx, name_y), _mover.name, HORIZONTAL_ALIGNMENT_LEFT, -1, DEBUG_FONT_SIZE, Color.WHITE)

    var req_f := "F" if _need_requested.get(Worker.NeedType.FOOD, false) else "f"
    var req_d := "D" if _need_requested.get(Worker.NeedType.DRINK, false) else "d"
    var req_c := "C" if _need_requested.get(Worker.NeedType.CLOTHING, false) else "c"
    var req_t := "T" if _need_requested.get(Worker.NeedType.TOOL, false) else "t"
    draw_string(font, Vector2(bx, name_y - line_h), "req:%s%s%s%s" % [req_f, req_d, req_c, req_t], HORIZONTAL_ALIGNMENT_LEFT, -1, DEBUG_FONT_SIZE, Color.YELLOW)

    var active_str := ""
    for entry in _active_needs:
        active_str += _need_short_name(entry.need) + " "
    if active_str.is_empty():
        active_str = "-"
    draw_string(font, Vector2(bx, name_y - line_h * 2.0), "act:" + active_str.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, DEBUG_FONT_SIZE, Color.CYAN)

func _need_short_name(need: int) -> String:
    match need:
        Worker.NeedType.FOOD: return "Food"
        Worker.NeedType.DRINK: return "Drnk"
        Worker.NeedType.CLOTHING: return "Clth"
        Worker.NeedType.TOOL: return "Tool"
    return "?"
