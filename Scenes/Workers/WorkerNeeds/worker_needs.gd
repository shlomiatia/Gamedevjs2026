class_name WorkerNeeds
extends Node2D

signal needs_satisfied
signal died

const INITIAL_HUNGER := 200.0
const HUNGER_DRAIN_NORMAL := 1.0
const HUNGER_DRAIN_WORKING := 2.0
const HUNGER_EAT_THRESHOLD := INITIAL_HUNGER * 0.5

const INITIAL_THIRST := 200.0
const THIRST_DRAIN_NORMAL := 1.0
const THIRST_DRAIN_WALKING := 2.0
const THIRST_DRINK_THRESHOLD := INITIAL_THIRST * 0.5

const INITIAL_CLOTHING := 200.0
const CLOTHING_DRAIN := 1.0
const CLOTHING_WEAR_THRESHOLD := INITIAL_CLOTHING * 0.5

const BAR_WIDTH := 32.0
const BAR_HEIGHT := 4.0
const BAR_Y := -68.0
const THIRST_BAR_Y := BAR_Y - BAR_HEIGHT - 2.0
const CLOTHING_BAR_Y := THIRST_BAR_Y - BAR_HEIGHT - 2.0
const MOVE_SPEED := 80.0

var hunger := INITIAL_HUNGER
var thirst := INITIAL_THIRST
var clothing := INITIAL_CLOTHING

var _mover: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _is_working := false
var _is_dead := false
var _need_requested: Dictionary = {}
var _active_needs: Array = []
var _path: Array[Vector2] = []

func setup(mover: Node2D, map: Map, coordination_manager: Node) -> void:
    _mover = mover
    _map = map
    _coordination_manager = coordination_manager

func set_working(val: bool) -> void:
    _is_working = val

func is_satisfying_need() -> bool:
    return not _active_needs.is_empty()

func get_need_value(need: int) -> float:
    match need:
        Worker.NeedType.FOOD: return hunger
        Worker.NeedType.DRINK: return thirst
        Worker.NeedType.CLOTHING: return clothing
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
        _path = _map.find_path(_mover.position, pile.global_position)

func _finish_need_trip() -> void:
    var entry: Dictionary = _active_needs[0]
    assert(is_instance_valid(entry.pile), "need pile is no longer valid")
    var resource: Node2D = (entry.pile as ResourcePile).collect(_mover)
    var satisfaction: float = resource.NEED_SATISFACTION_VALUE
    resource.queue_free()
    match entry.need:
        Worker.NeedType.FOOD: hunger = minf(INITIAL_HUNGER, hunger + satisfaction)
        Worker.NeedType.DRINK: thirst = minf(INITIAL_THIRST, thirst + satisfaction)
        Worker.NeedType.CLOTHING: clothing = minf(INITIAL_CLOTHING, clothing + satisfaction)
    _need_requested[entry.need] = false
    _active_needs.remove_at(0)
    _path.clear()

    if not _active_needs.is_empty():
        _path = _map.find_path(_mover.position, _active_needs[0].pile.global_position)
    else:
        needs_satisfied.emit()

func _process(delta: float) -> void:
    if _is_dead:
        return

    var hunger_drain := HUNGER_DRAIN_WORKING if _is_working else HUNGER_DRAIN_NORMAL
    hunger = maxf(0.0, hunger - hunger_drain * delta)
    var thirst_drain := THIRST_DRAIN_WALKING if not _path.is_empty() else THIRST_DRAIN_NORMAL
    thirst = maxf(0.0, thirst - thirst_drain * delta)
    clothing = maxf(0.0, clothing - CLOTHING_DRAIN * delta)

    if hunger == 0.0 or thirst == 0.0 or clothing == 0.0:
        _is_dead = true
        died.emit()
        return

    if _coordination_manager != null:
        if not _need_requested.get(Worker.NeedType.FOOD, false) and hunger < HUNGER_EAT_THRESHOLD:
            _need_requested[Worker.NeedType.FOOD] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.FOOD)
        if not _need_requested.get(Worker.NeedType.DRINK, false) and thirst < THIRST_DRINK_THRESHOLD:
            _need_requested[Worker.NeedType.DRINK] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.DRINK)
        if not _need_requested.get(Worker.NeedType.CLOTHING, false) and clothing < CLOTHING_WEAR_THRESHOLD:
            _need_requested[Worker.NeedType.CLOTHING] = true
            _coordination_manager.queue_need_collection(_mover, Worker.NeedType.CLOTHING)

    if not _active_needs.is_empty():
        if _move_along_path(delta):
            _finish_need_trip()

    queue_redraw()

func _move_along_path(delta: float) -> bool:
    if _path.is_empty():
        return true
    var target := _path[0]
    var dir := target - _mover.position
    var dist := dir.length()
    var step := MOVE_SPEED * delta
    if step >= dist:
        _mover.position = target
        _path.remove_at(0)
        return _path.is_empty()
    else:
        _mover.position += dir.normalized() * step
        return false

func _draw() -> void:
    var bx := -BAR_WIDTH * 0.5
    draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
    draw_rect(Rect2(bx, THIRST_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
    draw_rect(Rect2(bx, CLOTHING_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))

    var hr := hunger / INITIAL_HUNGER
    if hr > 0.0:
        var hc := Color(0.25, 0.8, 0.25) if hr > 0.5 else (Color(0.9, 0.7, 0.1) if hr > 0.25 else Color(0.9, 0.2, 0.2))
        draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH * hr, BAR_HEIGHT), hc)

    var tr_ratio := thirst / INITIAL_THIRST
    if tr_ratio > 0.0:
        var tc := Color(0.2, 0.6, 0.9) if tr_ratio > 0.5 else (Color(0.9, 0.8, 0.2) if tr_ratio > 0.25 else Color(0.9, 0.3, 0.1))
        draw_rect(Rect2(bx, THIRST_BAR_Y, BAR_WIDTH * tr_ratio, BAR_HEIGHT), tc)

    var cr := clothing / INITIAL_CLOTHING
    if cr > 0.0:
        var cc := Color(0.7, 0.3, 0.9) if cr > 0.5 else (Color(0.9, 0.7, 0.1) if cr > 0.25 else Color(0.9, 0.2, 0.2))
        draw_rect(Rect2(bx, CLOTHING_BAR_Y, BAR_WIDTH * cr, BAR_HEIGHT), cc)
