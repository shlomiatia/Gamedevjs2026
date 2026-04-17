class_name Worker
extends Node2D

signal died

enum NeedType { FOOD = 0, DRINK = 1, CLOTHING = 2 }
const NO_NEED := -1

const MAX_HUNGER := 200.0
const HUNGER_DRAIN_NORMAL := 1.0
const HUNGER_DRAIN_WORKING := 2.0
const HUNGER_EAT_THRESHOLD := MAX_HUNGER * 0.5

const MAX_THIRST := 200.0
const THIRST_DRAIN_NORMAL := 1.0
const THIRST_DRAIN_WALKING := 2.0
const THIRST_DRINK_THRESHOLD := MAX_THIRST * 0.5

const MAX_CLOTHING := 200.0
const CLOTHING_DRAIN := 1.0
const CLOTHING_WEAR_THRESHOLD := MAX_CLOTHING * 0.5

const BAR_WIDTH := 32.0
const BAR_HEIGHT := 4.0
const BAR_Y := -68.0
const THIRST_BAR_Y := BAR_Y - BAR_HEIGHT - 2.0
const CLOTHING_BAR_Y := THIRST_BAR_Y - BAR_HEIGHT - 2.0

var move_speed := 80.0
var hunger := MAX_HUNGER
var thirst := MAX_THIRST
var clothing := MAX_CLOTHING
var _is_dead := false
var _is_working := false

var _home: Node2D = null
var _map: Map = null
var _path: Array[Vector2] = []
var _carried_resource: Node2D = null

var _coordination_manager: Node = null
var _food_requested := false
var _drink_requested := false
var _clothing_requested := false

var _active_need := NO_NEED
var _active_need_pile: ResourcePile = null
var _pending_need := NO_NEED
var _pending_need_pile: ResourcePile = null
var _has_saved_destination := false
var _saved_destination := Vector2.ZERO

func setup(home: Node2D, map: Map) -> void:
	_home = home
	_map = map

func setup_food(coordination_manager: Node) -> void:
	_coordination_manager = coordination_manager

func set_working(val: bool) -> void:
	_is_working = val

func home_world_pos() -> Vector2:
	return _home.position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)

func navigate_to(world_pos: Vector2) -> void:
	var parent := get_parent() as Node2D
	_path = _map.find_path(parent.position, world_pos)

func tick_movement(delta: float) -> bool:
	if is_satisfying_need():
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

func is_satisfying_need() -> bool:
	return _active_need != NO_NEED

func is_pile_full(pile: ResourcePile, capacity: int) -> bool:
	return pile.get_child_count() >= capacity

func go_eat_food(pile: ResourcePile) -> void:
	_receive_need(pile, NeedType.FOOD)

func go_drink_cider(pile: ResourcePile) -> void:
	_receive_need(pile, NeedType.DRINK)

func go_wear_clothes(pile: ResourcePile) -> void:
	_receive_need(pile, NeedType.CLOTHING)

func _get_need_value(need: int) -> float:
	match need:
		NeedType.FOOD: return hunger
		NeedType.DRINK: return thirst
		NeedType.CLOTHING: return clothing
	return INF

func _receive_need(pile: ResourcePile, need: int) -> void:
	if _active_need == NO_NEED:
		if not _has_saved_destination:
			_has_saved_destination = not _path.is_empty()
			if _has_saved_destination:
				_saved_destination = _path.back()
		_path.clear()
		_active_need = need
		_active_need_pile = pile
		_path = _map.find_path(get_parent().position, pile.global_position)
	else:
		var new_val := _get_need_value(need)
		var active_val := _get_need_value(_active_need)
		if new_val < active_val:
			_pending_need = _active_need
			_pending_need_pile = _active_need_pile
			_active_need = need
			_active_need_pile = pile
			_path.clear()
			_path = _map.find_path(get_parent().position, pile.global_position)
		else:
			_pending_need = need
			_pending_need_pile = pile

func _finish_need_trip() -> void:
	var collected := false
	if is_instance_valid(_active_need_pile):
		var resource := _active_need_pile.collect(get_parent())
		if resource != null:
			resource.queue_free()
			collected = true
	if collected:
		match _active_need:
			NeedType.FOOD: hunger = minf(MAX_HUNGER, hunger + MAX_HUNGER)
			NeedType.DRINK: thirst = minf(MAX_THIRST, thirst + MAX_THIRST)
			NeedType.CLOTHING: clothing = minf(MAX_CLOTHING, clothing + MAX_CLOTHING)
	match _active_need:
		NeedType.FOOD: _food_requested = false
		NeedType.DRINK: _drink_requested = false
		NeedType.CLOTHING: _clothing_requested = false
	_active_need_pile = null
	_active_need = NO_NEED
	_path.clear()

	if _pending_need != NO_NEED:
		var next_need := _pending_need
		var next_pile := _pending_need_pile
		_pending_need = NO_NEED
		_pending_need_pile = null
		_active_need = next_need
		_active_need_pile = next_pile
		_path = _map.find_path(get_parent().position, next_pile.global_position)
	elif _has_saved_destination:
		_has_saved_destination = false
		_path = _map.find_path(get_parent().position, _saved_destination)

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
		if not _food_requested and hunger < HUNGER_EAT_THRESHOLD:
			_food_requested = true
			_coordination_manager.queue_food_collection(get_parent())
		if not _drink_requested and thirst < THIRST_DRINK_THRESHOLD:
			_drink_requested = true
			_coordination_manager.queue_drink_collection(get_parent())
		if not _clothing_requested and clothing < CLOTHING_WEAR_THRESHOLD:
			_clothing_requested = true
			_coordination_manager.queue_clothing_collection(get_parent())

	if _active_need != NO_NEED:
		if _move_along_path(delta):
			_finish_need_trip()

	queue_redraw()

func _draw() -> void:
	var bx := -BAR_WIDTH * 0.5
	draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
	draw_rect(Rect2(bx, THIRST_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))
	draw_rect(Rect2(bx, CLOTHING_BAR_Y, BAR_WIDTH, BAR_HEIGHT), Color(0.15, 0.15, 0.15, 0.85))

	var hr := hunger / MAX_HUNGER
	if hr > 0.0:
		var hc := Color(0.25, 0.8, 0.25) if hr > 0.5 else (Color(0.9, 0.7, 0.1) if hr > 0.25 else Color(0.9, 0.2, 0.2))
		draw_rect(Rect2(bx, BAR_Y, BAR_WIDTH * hr, BAR_HEIGHT), hc)

	var tr_ratio := thirst / MAX_THIRST
	if tr_ratio > 0.0:
		var tc := Color(0.2, 0.6, 0.9) if tr_ratio > 0.5 else (Color(0.9, 0.8, 0.2) if tr_ratio > 0.25 else Color(0.9, 0.3, 0.1))
		draw_rect(Rect2(bx, THIRST_BAR_Y, BAR_WIDTH * tr_ratio, BAR_HEIGHT), tc)

	var cr := clothing / MAX_CLOTHING
	if cr > 0.0:
		var cc := Color(0.7, 0.3, 0.9) if cr > 0.5 else (Color(0.9, 0.7, 0.1) if cr > 0.25 else Color(0.9, 0.2, 0.2))
		draw_rect(Rect2(bx, CLOTHING_BAR_Y, BAR_WIDTH * cr, BAR_HEIGHT), cc)
