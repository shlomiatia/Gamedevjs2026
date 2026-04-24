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

var uses_tools: bool = true

var _need_icon: Sprite2D = null
var _need_icon_textures: Dictionary = {}
var _strike_line: Line2D = null

var _blocked_by_needs: Dictionary = {}

var _mover: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _navigator: WorkerNavigator = null
var _is_working := false
var _is_dead := false
var _need_requested: Dictionary = {}
var _active_needs: Array = []

func _ready() -> void:
    _need_icon_textures = {
        Worker.NeedType.FOOD: load("res://Textures/food.png"),
        Worker.NeedType.DRINK: load("res://Textures/drink.png"),
        Worker.NeedType.CLOTHING: load("res://Textures/Clothes.png"),
        Worker.NeedType.TOOL: load("res://Textures/tool.png"),
    }
    _need_icon = Sprite2D.new()
    _need_icon.position = Vector2(0.0, NUM_Y)
    _need_icon.scale = Vector2(0.5, 0.5)
    _need_icon.visible = false
    add_child(_need_icon)
    _strike_line = Line2D.new()
    _strike_line.add_point(Vector2(-16.0, -16.0))
    _strike_line.add_point(Vector2(16.0, 16.0))
    _strike_line.default_color = Color(1.0, 0.15, 0.15, 1.0)
    _strike_line.width = 6.0
    _strike_line.visible = false
    _need_icon.add_child(_strike_line)

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

func is_waiting_for_need() -> bool:
    return _active_needs.is_empty() && !_blocked_by_needs.is_empty()

func get_need_value(need: int) -> float:
    match need:
        Worker.NeedType.FOOD: return hunger
        Worker.NeedType.DRINK: return thirst
        Worker.NeedType.CLOTHING: return clothing
        Worker.NeedType.TOOL: return _tool
    return INF

func handle_need(need: int, pile: ResourcePile, resource_type: int) -> void:
    assert(need != Worker.NO_NEED, "handle_need called with NO_NEED")
    _receive_need(need, pile, resource_type)

func _receive_need(need: int, pile: ResourcePile, resource_type: int) -> void:
    for entry in _active_needs:
        if entry.need == need:
            return

    var new_val := get_need_value(need)
    var insert_at := _active_needs.size()
    for i in _active_needs.size():
        if get_need_value(_active_needs[i].need) > new_val:
            insert_at = i
            break
    _active_needs.insert(insert_at, {need = need, pile = pile, resource_type = resource_type})

    if insert_at == 0:
        _navigator.navigate_to(pile.global_position)

func _finish_need_trip() -> void:
    var entry: Dictionary = _active_needs[0]
    assert(is_instance_valid(entry.pile), "need pile is no longer valid")
    var resource: Node2D = (entry.pile as ResourcePile).collect(_mover)
    resource.queue_free()
    var satisfaction: float = (_coordination_manager as CoordinationManager).get_satisfaction_for_resource(entry.resource_type)
    match entry.need:
        Worker.NeedType.FOOD: hunger = hunger + satisfaction
        Worker.NeedType.DRINK: thirst = thirst + satisfaction
        Worker.NeedType.CLOTHING: clothing = clothing + satisfaction
        Worker.NeedType.TOOL: _tool = _tool + satisfaction
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
    if is_working and uses_tools:
        _tool = maxf(0.0, _tool - 3.0 * delta)

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
        if not _need_requested.get(Worker.NeedType.CLOTHING, false) and clothing < Constants.clothing_threshold:
            _need_requested[Worker.NeedType.CLOTHING] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.CLOTHING)
        if not _blocked_by_needs.get(Worker.NeedType.CLOTHING, false) and clothing == 0.0:
            _blocked_by_needs[Worker.NeedType.CLOTHING] = true
            var w := _mover.get_node_or_null("Worker") as Worker
            if w != null:
                (_coordination_manager as CoordinationManager).notify_clothes_unusable(w.display_name)
        if uses_tools:
            if not _need_requested.get(Worker.NeedType.TOOL, false) and _tool < Constants.tool_threshold:
                _need_requested[Worker.NeedType.TOOL] = true
                _coordination_manager.queue_need_collection(_mover, Worker.NeedType.TOOL)
            if not _blocked_by_needs.get(Worker.NeedType.TOOL, false) and _tool == 0.0:
                _blocked_by_needs[Worker.NeedType.TOOL] = true
                var w := _mover.get_node_or_null("Worker") as Worker
                if w != null:
                    (_coordination_manager as CoordinationManager).notify_tool_broken(w.display_name)

    if not _active_needs.is_empty():
        if _navigator.tick(delta):
            _finish_need_trip()

    _update_need_icon()

func _update_need_icon() -> void:
    if _need_icon == null:
        return
    if _active_needs.is_empty() and _blocked_by_needs.is_empty():
        _need_icon.visible = false
        return
    var need: int
    var is_blocked: bool
    if not _active_needs.is_empty():
        need = _active_needs[0].need
        is_blocked = false
    else:
        need = _blocked_by_needs.keys()[0]
        is_blocked = true
    _need_icon.texture = _need_icon_textures.get(need)
    _need_icon.visible = true
    _strike_line.visible = is_blocked
