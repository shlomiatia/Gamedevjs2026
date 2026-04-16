class_name Woodcutter
extends Node2D

const MOVE_SPEED := 80.0
const CHOP_DURATION_MS := 3000.0
const OUTPUT_PILE_CAPACITY := 8
const IDLE_CHECK_INTERVAL := 0.5

const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

enum State { IDLE, GO_TO_TREE, CHOP, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _path: Array[Vector2] = []
var _woodcutter_hut: WoodcutterHut = null
var _map: Map = null
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _chop_elapsed := 0.0
var _carried_log: Node2D = null
var _idle_timer := 0.0

func setup(woodcutter_hut: WoodcutterHut, map: Map) -> void:
	_woodcutter_hut = woodcutter_hut
	_map = map

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
	return _woodcutter_hut.position + Vector2(0, float(_map.get_tile_size().y) * 0.5)

func _is_output_full() -> bool:
	return _woodcutter_hut.get_node("OutputPile").get_child_count() >= OUTPUT_PILE_CAPACITY

func _try_find_tree(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = IDLE_CHECK_INTERVAL

	if _is_output_full():
		return

	var best_tree: GameTree = null
	var best_dist := INF
	var best_tile := Vector2i.ZERO

	for tile: Vector2i in _map.occupied_tiles:
		var obj = _map.occupied_tiles[tile]
		if not (obj is GameTree):
			continue
		var tree := obj as GameTree
		if tree.targeted:
			continue
		var dist: float = tree.position.distance_to(_woodcutter_hut.position)
		if dist <= WoodcutterHut.SEARCH_RADIUS and dist < best_dist:
			best_dist = dist
			best_tree = tree
			best_tile = tile

	if best_tree == null:
		return

	best_tree.targeted = true
	_target_tree = best_tree
	_target_tree_tile = best_tile
	_path = _map.find_path(position, _map.tile_to_world(_target_tree_tile))
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
	_map.occupied_tiles.erase(_target_tree_tile)
	_target_tree.queue_free()
	_target_tree = null

	var log_node := LogScene.instantiate() as Node2D
	log_node.position = Vector2(0, -48)
	add_child(log_node)
	_carried_log = log_node

	_path = _map.find_path(position, _home_world_pos())
	_state = State.GO_HOME

func _try_deposit() -> void:
	if _is_output_full():
		return
	if _carried_log:
		var output_pile := _woodcutter_hut.get_node("OutputPile") as ResourcePile
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
