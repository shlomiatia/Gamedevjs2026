class_name Builder
extends Node2D

const MOVE_SPEED := 160.0
const BUILD_DURATION_MS := 5000.0

enum State { IDLE, GO_TO_PICKUP, GO_TO_SITE, BUILD, GO_HOME }

var _state := State.IDLE
var _path: Array[Vector2] = []
var _target_hut: WoodcutterHut = null
var _home_hut: Node2D = null
var _building_manager: Node2D = null
var _coordination_manager: Node = null
var _grass_layer: TileMapLayer = null
var _tile_size: Vector2i
var _build_elapsed := 0.0
var _carried_log: Node2D = null

func setup(home_hut: Node2D, building_manager: Node2D, grass_layer: TileMapLayer, coordination_manager: Node, tile_size: Vector2i) -> void:
    _home_hut = home_hut
    _building_manager = building_manager
    _grass_layer = grass_layer
    _coordination_manager = coordination_manager
    _tile_size = tile_size
    coordination_manager.register_builder(self)

func is_free() -> bool:
    return _state == State.IDLE or _state == State.GO_HOME

func assign_build_task(target: WoodcutterHut) -> void:
    if not is_free():
        return
    _target_hut = target
    _navigate_to(_home_world_pos())
    _state = State.GO_TO_PICKUP

func _process(delta: float) -> void:
    match _state:
        State.GO_TO_PICKUP, State.GO_TO_SITE, State.GO_HOME:
            _move_along_path(delta)
        State.BUILD:
            _do_build(delta)

func _home_world_pos() -> Vector2:
    return _home_hut.position + Vector2(0, float(_tile_size.y) * 0.5)

func _site_world_pos() -> Vector2:
    return _target_hut.position + Vector2(0, float(_tile_size.y) * 0.5)

func _navigate_to(target: Vector2) -> void:
    var from_tile := _grass_layer.local_to_map(position)
    var to_tile := _grass_layer.local_to_map(target)
    var tile_path := _astar(from_tile, to_tile)
    _path.clear()
    for t in tile_path:
        _path.append(_grass_layer.map_to_local(t))

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
        State.GO_TO_PICKUP:
            _do_pickup()
        State.GO_TO_SITE:
            _state = State.BUILD
            _build_elapsed = 0.0
        State.GO_HOME:
            _state = State.IDLE

func _do_pickup() -> void:
    var output_pile: Node2D = _home_hut.get_node("OutputPile")
    if output_pile.get_child_count() == 0:
        _state = State.IDLE
        return
    var log_node := output_pile.get_child(output_pile.get_child_count() - 1)
    output_pile.remove_child(log_node)
    log_node.position = Vector2(0, -48)
    add_child(log_node)
    _carried_log = log_node
    _navigate_to(_site_world_pos())
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
        _navigate_to(_home_world_pos())

# A* pathfinding on the tile grid
func _astar(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
    if from == to:
        return [to]

    var occupied: Dictionary = _building_manager.occupied_tiles
    var bounds: Rect2i = _grass_layer.get_used_rect()

    var open_set: Array[Vector2i] = [from]
    var came_from: Dictionary = {}
    var g_score: Dictionary = {from: 0.0}
    var f_score: Dictionary = {from: _heuristic(from, to)}

    var iterations := 0

    while not open_set.is_empty() and iterations < 10000:
        iterations += 1

        var current_idx := 0
        for i in open_set.size():
            if f_score.get(open_set[i], INF) < f_score.get(open_set[current_idx], INF):
                current_idx = i
        var current: Vector2i = open_set[current_idx]

        if current == to:
            return _reconstruct_path(came_from, current)

        open_set.remove_at(current_idx)

        for neighbor in _get_neighbors(current, bounds):
            if occupied.has(neighbor) and neighbor != to:
                continue
            var tentative_g: float = g_score.get(current, INF) + 1.0
            if tentative_g < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + _heuristic(neighbor, to)
                if not open_set.has(neighbor):
                    open_set.append(neighbor)

    return [to]

func _heuristic(a: Vector2i, b: Vector2i) -> float:
    return float(abs(a.x - b.x) + abs(a.y - b.y))

func _get_neighbors(tile: Vector2i, bounds: Rect2i) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var n: Vector2i = tile + offset
        if bounds.has_point(n):
            result.append(n)
    return result

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = [current]
    while came_from.has(current):
        current = came_from[current]
        path.push_front(current)
    return path
