class_name AppleFarmer
extends Node2D


const AppleScene = preload("res://Scenes/Resources/Apple/Apple.tscn")

enum State { IDLE, GO_TO_TREE, PICK, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _apple_farm: AppleFarm = null
var _map: Map = null
var _forest: Forest = null
var _target_tree: GameTree = null
var _target_tree_tile: Vector2i
var _pick_elapsed := 0.0

func setup(apple_farm: AppleFarm, map: Map, forest: Forest, coordination_manager: Node) -> void:
    _apple_farm = apple_farm
    _map = map
    _forest = forest
    $Worker.setup(apple_farm, map, coordination_manager)
    $Worker.display_name = "Apple Farmer"

func resume_work() -> void:
    match _state:
        State.GO_TO_TREE, State.PICK:
            _state = State.GO_TO_TREE
            $Worker.navigate_to(_map.tile_to_world(_target_tree_tile))
        State.GO_HOME, State.DEPOSIT:
            _state = State.GO_HOME
            $Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
    $Worker.set_working(_state == State.PICK)
    if $Worker.is_satisfying_need():
        return
    match _state:
        State.IDLE:
            _try_find_tree()
        State.GO_TO_TREE, State.GO_HOME:
            if $Worker.tick_movement(delta):
                _on_path_finished()
        State.PICK:
            _do_pick(delta)
        State.DEPOSIT:
            _try_deposit()

func _output_pile() -> ResourcePile:
    return _apple_farm.get_pile_for_type(CoordinationManager.ResourceType.APPLE)

func _try_find_tree() -> void:
    if $Worker.is_output_full(_output_pile()):
        return
    var result := _forest.find_tree(_apple_farm.position, true)
    if result.is_empty():
        return
    var best_tree := result["tree"] as GameTree
    var best_tile := result["tile"] as Vector2i
    best_tree.targeted = true
    _target_tree = best_tree
    _target_tree_tile = best_tile
    $Worker.navigate_to(_map.tile_to_world(_target_tree_tile))
    _state = State.GO_TO_TREE

func _do_pick(delta: float) -> void:
    assert(is_instance_valid(_target_tree), "target tree freed while picking")
    _pick_elapsed += delta * 1000.0
    var progress := clampf(_pick_elapsed / Constants.pick_duration_ms, 0.0, 1.0)
    _target_tree.set_pick_progress(progress)
    if _pick_elapsed >= Constants.pick_duration_ms:
        _finish_pick()

func _finish_pick() -> void:
    _target_tree.remove_apples()
    _target_tree = null
    $Worker.carry(AppleScene.instantiate() as Node2D)
    $Worker.navigate_to($Worker.home_world_pos())
    _state = State.GO_HOME

func _try_deposit() -> void:
    assert(not $Worker.is_output_full(_output_pile()), "_try_deposit: output pile is full")
    _output_pile().add_existing_resource($Worker.drop())
    _state = State.IDLE

func _on_path_finished() -> void:
    match _state:
        State.GO_TO_TREE:
            _state = State.PICK
            _pick_elapsed = 0.0
        State.GO_HOME:
            _state = State.DEPOSIT
