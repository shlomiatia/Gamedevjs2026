class_name WorkerNavigator
extends Node

var move_speed := 80.0
var _mover: Node2D = null
var _home: Node2D = null
var _map: Map = null
var _path: Array[Vector2] = []

func setup(mover: Node2D, home: Node2D, map: Map) -> void:
	_mover = mover
	_home = home
	_map = map

func home_world_pos() -> Vector2:
	return _home.position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)

func navigate_to(world_pos: Vector2) -> void:
	_path = _map.find_path(_mover.position, world_pos)
	assert(not _path.is_empty(), "WorkerNavigator: no path found to %s" % world_pos)

func tick(delta: float) -> bool:
	return _move_along_path(delta)

func is_moving() -> bool:
	return not _path.is_empty()

func _move_along_path(delta: float) -> bool:
	if _path.is_empty():
		return true
	var target := _path[0]
	var dir := target - _mover.position
	var dist := dir.length()
	var step := move_speed * delta
	if step >= dist:
		_mover.position = target
		_path.remove_at(0)
		return _path.is_empty()
	else:
		_mover.position += dir.normalized() * step
		return false
