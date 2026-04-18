class_name Woodcutter
extends Node2D


const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

enum State { IDLE, GO_TO_TREE, CHOP, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _woodcutter_hut: WoodcutterHut = null
var _map: Map = null
var _forest: Forest = null
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _chop_elapsed := 0.0

func setup(woodcutter_hut: WoodcutterHut, map: Map, forest: Forest, coordination_manager: Node) -> void:
	_woodcutter_hut = woodcutter_hut
	_map = map
	_forest = forest
	$Worker.setup(woodcutter_hut, map, coordination_manager)

func resume_work() -> void:
	match _state:
		State.GO_TO_TREE, State.CHOP:
			_state = State.GO_TO_TREE
			$Worker.navigate_to(_map.tile_to_world(_target_tree_tile))
		State.GO_HOME, State.DEPOSIT:
			_state = State.GO_HOME
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.CHOP)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.IDLE:
			_try_find_tree()
		State.GO_TO_TREE, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.CHOP:
			_do_chop(delta)
		State.DEPOSIT:
			_try_deposit()

func _output_pile() -> ResourcePile:
	return _woodcutter_hut.get_node("Building/OutputPile") as ResourcePile

func _try_find_tree() -> void:
	if $Worker.is_output_full(_output_pile(), Constants.output_pile_capacity):
		return
	var result := _forest.find_tree(_woodcutter_hut.position, false)
	if result.is_empty():
		return
	var best_tree := result["tree"] as GameTree
	var best_tile := result["tile"] as Vector2i
	best_tree.targeted = true
	_target_tree = best_tree
	_target_tree_tile = best_tile
	$Worker.navigate_to(_map.tile_to_world(_target_tree_tile))
	_state = State.GO_TO_TREE

func _do_chop(delta: float) -> void:
	assert(is_instance_valid(_target_tree), "target tree freed while chopping")
	_chop_elapsed += delta * 1000.0
	var progress: float = clampf(_chop_elapsed / Constants.chop_duration_ms, 0.0, 1.0)
	_target_tree.set_chop_progress(progress)
	if progress >= 1.0:
		_finish_chop()

func _finish_chop() -> void:
	_forest.remove_tree(_target_tree_tile)
	_target_tree.queue_free()
	_target_tree = null
	$Worker.carry(LogScene.instantiate() as Node2D)
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME

func _try_deposit() -> void:
	assert(not $Worker.is_output_full(_output_pile(), Constants.output_pile_capacity), "_try_deposit: output pile is full")
	_output_pile().add_existing_resource($Worker.drop())
	_state = State.IDLE

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_TREE:
			_state = State.CHOP
			_chop_elapsed = 0.0
		State.GO_HOME:
			_state = State.DEPOSIT
