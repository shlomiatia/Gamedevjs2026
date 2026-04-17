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
var _forest: Forest = null
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _pick_elapsed := 0.0
var _idle_timer := 0.0

func setup(apple_farm: AppleFarm, map: Map, forest: Forest, coordination_manager: Node) -> void:
	_apple_farm = apple_farm
	_map = map
	_forest = forest
	$Worker.setup(apple_farm, map)
	$Worker.setup_food(coordination_manager)
	$Worker.died.connect(func():
		_apple_farm.on_worker_died()
		queue_free()
	)

func go_eat_food(pile: ResourcePile) -> void:
	$Worker.go_eat_food(pile)

func go_drink_cider(pile: ResourcePile) -> void:
	$Worker.go_drink_cider(pile)

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.PICK)
	match _state:
		State.IDLE:
			if not $Worker.is_satisfying_need():
				_try_find_tree(delta)
		State.GO_TO_TREE, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.PICK:
			if not $Worker.is_satisfying_need():
				_do_pick(delta)
		State.DEPOSIT:
			if not $Worker.is_satisfying_need():
				_try_deposit()

func _output_pile() -> ResourcePile:
	return _apple_farm.get_node("Building/OutputPile") as ResourcePile

func _is_output_full() -> bool:
	return $Worker.is_pile_full(_output_pile(), OUTPUT_PILE_CAPACITY)

func _try_find_tree(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = IDLE_CHECK_INTERVAL

	if _is_output_full():
		return

	var result := _forest.find_tree(_apple_farm.position, true)
	if result.is_empty():
		return

	var best_tree := result["tree"] as GameTree
	var best_tile := result["tile"] as Vector2i
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
