class_name Woodcutter
extends Node2D

const OUTPUT_PILE_CAPACITY := 8
const IDLE_CHECK_INTERVAL := 0.5
const CHOP_DURATION_MS := 3000.0

const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

enum State { IDLE, GO_TO_TREE, CHOP, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _woodcutter_hut: WoodcutterHut = null
var _map: Map = null
var _forest: Forest = null
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _chop_elapsed := 0.0
var _idle_timer := 0.0

func setup(woodcutter_hut: WoodcutterHut, map: Map, forest: Forest) -> void:
	_woodcutter_hut = woodcutter_hut
	_map = map
	_forest = forest
	$Worker.setup(woodcutter_hut, map)
	$Worker.died.connect(func():
		_woodcutter_hut.on_worker_died()
		queue_free()
	)

func _process(delta: float) -> void:
	match _state:
		State.IDLE:
			_try_find_tree(delta)
		State.GO_TO_TREE, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.CHOP:
			_do_chop(delta)
		State.DEPOSIT:
			_try_deposit()

func _output_pile() -> ResourcePile:
	return _woodcutter_hut.get_node("OutputPile") as ResourcePile

func _is_output_full() -> bool:
	return $Worker.is_pile_full(_output_pile(), OUTPUT_PILE_CAPACITY)

func _try_find_tree(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = IDLE_CHECK_INTERVAL

	if _is_output_full():
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
	if not is_instance_valid(_target_tree):
		_state = State.IDLE
		return
	_chop_elapsed += delta * 1000.0
	var progress: float = clampf(_chop_elapsed / CHOP_DURATION_MS, 0.0, 1.0)
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
	if _is_output_full():
		return
	_output_pile().add_existing_resource($Worker.drop())
	_state = State.IDLE

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_TREE:
			_state = State.CHOP
			_chop_elapsed = 0.0
		State.GO_HOME:
			_state = State.DEPOSIT
