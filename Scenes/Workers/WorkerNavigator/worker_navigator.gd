class_name WorkerNavigator
extends Node

var _mover: Node2D = null
var _home: Node2D = null
var _map: Map = null
var _agent: NavigationAgent2D = null
var _facing: Vector2 = Vector2(0, 1)

func setup(mover: Node2D, home: Node2D, map: Map, agent: NavigationAgent2D) -> void:
	_mover = mover
	_home = home
	_map = map
	_agent = agent

func home_world_pos() -> Vector2:
	return _home.position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)

func navigate_to(world_pos: Vector2) -> void:
	_agent.target_position = world_pos

func tick(delta: float) -> bool:
	if _agent.is_navigation_finished():
		return true
	var next: Vector2 = _agent.get_next_path_position()
	var dir := next - _mover.position
	var dist := dir.length()
	if dist > 0.5:
		_facing = dir.normalized()
	var step := Constants.worker_move_speed * delta
	if step >= dist:
		_mover.position += dir
	else:
		_mover.position += dir.normalized() * step
	return _agent.is_navigation_finished()

func is_moving() -> bool:
	if _agent.is_navigation_finished():
		return false
	return _agent.get_next_path_position().distance_squared_to(_mover.position) > 0.25

func get_facing() -> Vector2:
	return _facing
