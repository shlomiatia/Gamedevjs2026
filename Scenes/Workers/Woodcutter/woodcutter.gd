class_name Woodcutter
extends Node2D

const MOVE_SPEED := 80.0
const CHOP_DURATION_MS := 3000.0
const SEARCH_RADIUS := 300.0
const OUTPUT_PILE_CAPACITY := 8
const IDLE_CHECK_INTERVAL := 0.5

const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

enum State { IDLE, GO_TO_TREE, CHOP, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _path: Array[Vector2] = []
var _woodcutter_hut: Node2D = null
var _building_manager: Node2D = null
var _grass_layer: TileMapLayer = null
var _tile_size: Vector2i
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _chop_elapsed := 0.0
var _carried_log: Node2D = null
var _idle_timer := 0.0

func setup(woodcutter_hut: Node2D, building_manager: Node2D, grass_layer: TileMapLayer, tile_size: Vector2i) -> void:
	_woodcutter_hut = woodcutter_hut
	_building_manager = building_manager
	_grass_layer = grass_layer
	_tile_size = tile_size

func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_try_find_tree(delta)
		State.GO_TO_TREE, State.GO_HOME:
			_move_along_path(delta)
		State.CHOP:
			_do_chop(delta)
		State.DEPOSIT:
			_try_deposit()

func _home_world_pos() -> Vector2:
	return _woodcutter_hut.position + Vector2(0, float(_tile_size.y) * 0.5)

func _try_find_tree(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = IDLE_CHECK_INTERVAL

	var output_pile: Node2D = _woodcutter_hut.get_node("OutputPile")
	if output_pile.get_child_count() >= OUTPUT_PILE_CAPACITY:
		return

	var best_tree: GameTree = null
	var best_dist := INF
	var best_tile := Vector2i.ZERO

	for tile: Vector2i in _building_manager.occupied_tiles:
		var obj = _building_manager.occupied_tiles[tile]
		if not (obj is GameTree):
			continue
		var tree := obj as GameTree
		if tree.targeted:
			continue
		var dist: float = tree.position.distance_to(_woodcutter_hut.position)
		if dist <= SEARCH_RADIUS and dist < best_dist:
			best_dist = dist
			best_tree = tree
			best_tile = tile

	if best_tree == null:
		return

	best_tree.targeted = true
	_target_tree = best_tree
	_target_tree_tile = best_tile
	_navigate_to(_grass_layer.map_to_local(_target_tree_tile))
	_state = State.GO_TO_TREE

func _do_chop(delta: float) -> void:
	if not is_instance_valid(_target_tree):
		_state = State.IDLE
		return
	_chop_elapsed += delta * 1000.0
	var progress: float = clampf(_chop_elapsed / CHOP_DURATION_MS, 0.0, 1.0)
	_target_tree.set_chop_progress(progress)
	if progress >= 1.0:
		_finish_chop()

func _finish_chop() -> void:
	_building_manager.occupied_tiles.erase(_target_tree_tile)
	_target_tree.queue_free()
	_target_tree = null

	var log_node := LogScene.instantiate() as Node2D
	log_node.position = Vector2(0, -48)
	add_child(log_node)
	_carried_log = log_node

	_navigate_to(_home_world_pos())
	_state = State.GO_HOME

func _try_deposit() -> void:
	var output_pile := _woodcutter_hut.get_node("OutputPile") as ResourcePile
	if output_pile.get_child_count() >= OUTPUT_PILE_CAPACITY:
		return
	if _carried_log:
		remove_child(_carried_log)
		output_pile.add_existing_resource(_carried_log)
		_carried_log = null
	_state = State.IDLE

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_TREE:
			_state = State.CHOP
			_chop_elapsed = 0.0
		State.GO_HOME:
			_state = State.DEPOSIT

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
