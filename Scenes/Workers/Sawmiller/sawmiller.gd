class_name Sawmiller
extends Node2D

const MOVE_SPEED := 80.0
const WORK_DURATION_MS := 5000.0

const PlankScene = preload("res://Scenes/Resources/Plank/Plank.tscn")

enum State { WAIT_FOR_RESOURCE, GO_TO_RESOURCE, GO_HOME, WORK }

var _state := State.WAIT_FOR_RESOURCE
var _path: Array[Vector2] = []
var _sawmill: Sawmill = null
var _map: Map = null
var _coordination_manager: Node = null
var _target_pile: ResourcePile = null
var _carried_log: Node2D = null
var _work_elapsed := 0.0

func setup(sawmill: Sawmill, map: Map, coordination_manager: Node) -> void:
	_sawmill = sawmill
	_map = map
	_coordination_manager = coordination_manager

func _ready() -> void:
	_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)

func go_collect_resource(pile: ResourcePile) -> void:
	_target_pile = pile
	_path = _map.find_path(position, pile.global_position)
	_state = State.GO_TO_RESOURCE

func _process(delta: float) -> void:
	match _state:
		State.GO_TO_RESOURCE, State.GO_HOME:
			_move_along_path(delta)
		State.WORK:
			_do_work(delta)

func _home_world_pos() -> Vector2:
	return _sawmill.position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)

func _move_along_path(delta: float) -> void:
	if _path.is_empty():
		_on_path_finished()
		return
	var target := _path[0]
	var dir := target - position
	var dist := dir.length()
	var step := MOVE_SPEED * delta
	if step >= dist:
		position = target
		_path.remove_at(0)
		if _path.is_empty():
			_on_path_finished()
	else:
		position += dir.normalized() * step

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_RESOURCE:
			_do_collect()
		State.GO_HOME:
			_state = State.WORK
			_work_elapsed = 0.0

func _do_collect() -> void:
	var log_node := _target_pile.collect(self)
	_target_pile = null
	if log_node == null:
		_state = State.WAIT_FOR_RESOURCE
		_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)
		return
	log_node.position = Vector2(0, -48)
	add_child(log_node)
	_carried_log = log_node
	_path = _map.find_path(position, _home_world_pos())
	_state = State.GO_HOME

func _do_work(delta: float) -> void:
	_work_elapsed += delta * 1000.0
	if _work_elapsed >= WORK_DURATION_MS:
		_finish_work()

func _finish_work() -> void:
	if _carried_log:
		_carried_log.queue_free()
		_carried_log = null
	var output_pile := _sawmill.get_node("OutputPile") as ResourcePile
	output_pile.add_resource(PlankScene)
	_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)
	_state = State.WAIT_FOR_RESOURCE
