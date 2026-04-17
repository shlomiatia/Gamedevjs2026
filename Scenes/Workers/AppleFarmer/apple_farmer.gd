class_name AppleFarmer
extends Node2D

const OUTPUT_PILE_CAPACITY := 8
const IDLE_CHECK_INTERVAL := 0.5
const PICK_DURATION_MS := 2000.0

const AppleScene = preload("res://Scenes/Resources/Apple/Apple.tscn")

enum State { IDLE, GO_TO_TREE, PICK, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _apple_farm: AppleFarm = null
var _map: Map = null
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _pick_elapsed := 0.0
var _idle_timer := 0.0

func setup(apple_farm: AppleFarm, map: Map) -> void:
	_apple_farm = apple_farm
	_map = map
	$Worker.setup(apple_farm, map)

func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_try_find_tree(delta)
		State.GO_TO_TREE, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.PICK:
			_do_pick(delta)
		State.DEPOSIT:
			_try_deposit()

func _output_pile() -> ResourcePile:
	return _apple_farm.get_node("OutputPile") as ResourcePile

func _is_output_full() -> bool:
	return $Worker.is_pile_full(_output_pile(), OUTPUT_PILE_CAPACITY)

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

	for tile: Vector2i in _map.trees:
		var tree := _map.trees[tile] as GameTree
		if tree.apple_targeted or not tree.has_apples:
			continue
		var dist: float = tree.position.distance_to(_apple_farm.position)
		if dist <= AppleFarm.SEARCH_RADIUS and dist < best_dist:
			best_dist = dist
			best_tree = tree
			best_tile = tile

	if best_tree == null:
		return

	best_tree.apple_targeted = true
	_target_tree = best_tree
	_target_tree_tile = best_tile
	$Worker.navigate_to(_map.tile_to_world(_target_tree_tile))
	_state = State.GO_TO_TREE

func _do_pick(delta: float) -> void:
	if not is_instance_valid(_target_tree):
		_state = State.IDLE
		return
	_pick_elapsed += delta * 1000.0
	if _pick_elapsed >= PICK_DURATION_MS:
		_finish_pick()

func _finish_pick() -> void:
	_target_tree.remove_apples()
	_target_tree = null

	$Worker.carry(AppleScene.instantiate() as Node2D)
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME

func _try_deposit() -> void:
	if _is_output_full():
		return
	_output_pile().add_existing_resource($Worker.drop())
	_state = State.IDLE

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_TREE:
			_state = State.PICK
			_pick_elapsed = 0.0
		State.GO_HOME:
			_state = State.DEPOSIT
