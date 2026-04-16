class_name Builder
extends Node2D

const MOVE_SPEED := 80.0
const BUILD_DURATION_MS := 5000.0

enum State { IDLE, WAIT_FOR_RESOURCE, GO_TO_RESOURCE, GO_TO_SITE, BUILD, GO_HOME }

var _state := State.IDLE
var _path: Array[Vector2] = []
var _target_hut: Building = null
var _target_pile: ResourcePile = null
var _home_hut: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _build_elapsed := 0.0
var _carried_log: Node2D = null

func setup(home_hut: Node2D, map: Map, coordination_manager: Node) -> void:
    _home_hut = home_hut
    _map = map
    _coordination_manager = coordination_manager
    coordination_manager.register_builder(self)

func is_free() -> bool:
    return _state == State.IDLE or _state == State.GO_HOME

func assign_build_task(target: Building) -> void:
    if not is_free():
        return
    _target_hut = target
    _state = State.WAIT_FOR_RESOURCE
    _coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.PLANK)

func go_collect_resource(pile: ResourcePile) -> void:
    _target_pile = pile
    _path = _map.find_path(position, pile.global_position)
    _state = State.GO_TO_RESOURCE

func _process(delta: float) -> void:
    match _state:
        State.GO_TO_RESOURCE, State.GO_TO_SITE, State.GO_HOME:
            _move_along_path(delta)
        State.BUILD:
            _do_build(delta)

func _home_world_pos() -> Vector2:
    return _home_hut.position + Vector2(0, float(_map.get_tile_size().y) * 0.5)

func _site_world_pos() -> Vector2:
    return _target_hut.position + Vector2(0, float(_map.get_tile_size().y) * 0.5)

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
        State.GO_TO_SITE:
            _state = State.BUILD
            _build_elapsed = 0.0
        State.GO_HOME:
            _state = State.IDLE

func _do_collect() -> void:
    var log_node := _target_pile.collect(self)
    _target_pile = null
    if log_node == null:
        _state = State.WAIT_FOR_RESOURCE
        _coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.PLANK)
        return
    log_node.position = Vector2(0, -48)
    add_child(log_node)
    _carried_log = log_node
    _path = _map.find_path(position, _site_world_pos())
    _state = State.GO_TO_SITE

func _do_build(delta: float) -> void:
    _build_elapsed += delta * 1000.0
    var progress: float = clampf(_build_elapsed / BUILD_DURATION_MS, 0.0, 1.0)
    _target_hut.set_construction_progress(progress)
    if progress >= 1.0:
        _finish_build()

func _finish_build() -> void:
    if _carried_log:
        _carried_log.queue_free()
        _carried_log = null
    _target_hut.complete_construction()
    _target_hut = null
    _state = State.GO_HOME
    _coordination_manager.notify_idle_builder(self)
    if _state == State.GO_HOME:
        _path = _map.find_path(position, _home_world_pos())
