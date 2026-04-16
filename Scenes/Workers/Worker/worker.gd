class_name Worker
extends Node2D

var move_speed := 80.0

var _home: Node2D = null
var _map: Map = null
var _path: Array[Vector2] = []
var _carried_resource: Node2D = null

func setup(home: Node2D, map: Map) -> void:
	_home = home
	_map = map

func home_world_pos() -> Vector2:
	return _home.position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)

func navigate_to(world_pos: Vector2) -> void:
	var parent := get_parent() as Node2D
	_path = _map.find_path(parent.position, world_pos)

func tick_movement(delta: float) -> bool:
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

func is_pile_full(pile: ResourcePile, capacity: int) -> bool:
	return pile.get_child_count() >= capacity
