class_name Worker
extends Node2D

signal died

const MAX_HUNGER := 200.0
const HUNGER_DRAIN_IDLE := 1.0
const HUNGER_DRAIN_WALKING := 2.0
const HUNGER_EAT_THRESHOLD := MAX_HUNGER * 0.5

const BAR_WIDTH := 32.0
const BAR_HEIGHT := 4.0
const BAR_Y := -68.0

var move_speed := 80.0
var hunger := MAX_HUNGER
var _is_dead := false

var _home: Node2D = null
var _map: Map = null
var _path: Array[Vector2] = []
var _carried_resource: Node2D = null

var _coordination_manager: Node = null
var _food_requested := false
var _eating := false
var _food_pile: ResourcePile = null
var _has_saved_destination := false
var _saved_destination := Vector2.ZERO

func setup(home: Node2D, map: Map) -> void:
    _home = home
    _map = map

func setup_food(coordination_manager: Node) -> void:
    _coordination_manager = coordination_manager

func home_world_pos() -> Vector2:
    return _home.position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)

func navigate_to(world_pos: Vector2) -> void:
    var parent := get_parent() as Node2D
    _path = _map.find_path(parent.position, world_pos)

func tick_movement(delta: float) -> bool:
    if _eating:
        return false
    return _move_along_path(delta)

func _move_along_path(delta: float) -> bool:
    if _path.is_empty():
        return true
    var parent := get_parent() as Node2D
    var target := _path[0]
    var dir := target - parent.position
    var dist := dir.length()
    var step := move_speed * delta
    if step >= dist:
        parent.position = target
        _path.remove_at(0)
        return _path.is_empty()
    else:
        parent.position += dir.normalized() * step
        return false

func carry(resource: Node2D) -> void:
    resource.position = Vector2(0, -48)
    get_parent().add_child(resource)
    _carried_resource = resource

func drop() -> Node2D:
    var resource := _carried_resource
    _carried_resource = null
    if resource:
        get_parent().remove_child(resource)
    return resource

func is_carrying() -> bool:
    return _carried_resource != null

func is_eating() -> bool:
    return _eating

func is_pile_full(pile: ResourcePile, capacity: int) -> bool:
    return pile.get_child_count() >= capacity

func go_eat_food(pile: ResourcePile) -> void:
    _food_pile = pile
    _eating = true
    _has_saved_destination = not _path.is_empty()
    if _has_saved_destination:
        _saved_destination = _path.back()
    _path.clear()
    var parent := get_parent() as Node2D
    _path = _map.find_path(parent.position, pile.global_position)

func _finish_eating() -> void:
    if is_instance_valid(_food_pile):
        var food := _food_pile.collect(get_parent())
        if food:
            food.queue_free()
    hunger = minf(MAX_HUNGER, hunger + MAX_HUNGER)
    _food_pile = null
    _eating = false
    _food_requested = false
    _path.clear()
    if _has_saved_destination:
        _has_saved_destination = false
        var parent := get_parent() as Node2D
        _path = _map.find_path(parent.position, _saved_destination)

func _process(delta: float) -> void:
    if _is_dead:
        return
    var drain := HUNGER_DRAIN_WALKING if not _path.is_empty() else HUNGER_DRAIN_IDLE
    hunger = maxf(0.0, hunger - drain * delta)
    if hunger == 0.0:
        _is_dead = true
        died.emit()
        return
    if not _food_requested and not _eating and hunger < HUNGER_EAT_THRESHOLD and _coordination_manager != null:
        _food_requested = true
        _coordination_manager.queue_food_collection(get_parent())
    if _eating:
        if _move_along_path(delta):
            _finish_eating()
    queue_redraw()

func _draw() -> void:
    var ratio := hunger / MAX_HUNGER
    var bx := -BAR_WIDTH * 0.5
    draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
    var color: Color
    if ratio > 0.5:
        color = Color(0.25, 0.8, 0.25)
    elif ratio > 0.25:
        color = Color(0.9, 0.7, 0.1)
    else:
        color = Color(0.9, 0.2, 0.2)
    if ratio > 0.0:
        draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH * ratio, BAR_HEIGHT), color)
