class_name Miller
extends Node2D


enum State { WAIT_FOR_RESOURCE, GO_TO_RESOURCE, GO_HOME, GO_HOME_TO_WORK, WORK }

var _state := State.WAIT_FOR_RESOURCE
var _building: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _input_resource_type: int = -1
var _output_scene: PackedScene = null
var _output_pile: ResourcePile = null
var _target_pile: ResourcePile = null
var _work_elapsed := 0.0

func setup(building: Node2D, map: Map, coordination_manager: Node, input_resource_type: int, output_scene: PackedScene, output_pile: ResourcePile, worker_name: String = "Miller") -> void:
	_building = building
	_map = map
	_coordination_manager = coordination_manager
	_input_resource_type = input_resource_type
	_output_scene = output_scene
	_output_pile = output_pile
	$Worker.setup(building, map, coordination_manager)
	$Worker.display_name = worker_name

func go_collect_resource(pile: ResourcePile) -> void:
	_target_pile = pile
	_state = State.GO_TO_RESOURCE
	if not $Worker.is_satisfying_need():
		$Worker.navigate_to(pile.global_position)

func _ready() -> void:
	_coordination_manager.queue_resource_collection(self, _input_resource_type)

func resume_work() -> void:
	match _state:
		State.GO_TO_RESOURCE:
			$Worker.navigate_to(_target_pile.global_position)
		State.GO_HOME:
			$Worker.navigate_to($Worker.home_world_pos())
		State.WORK, State.GO_HOME_TO_WORK, State.WAIT_FOR_RESOURCE:
			_state = State.GO_HOME_TO_WORK
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	var working := _state == State.WORK
	$Worker.set_working(working)
	(_building.get_node("Building") as BuildingComponent).set_milling(working)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.GO_TO_RESOURCE, State.GO_HOME, State.GO_HOME_TO_WORK:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.WORK:
			_do_work(delta)

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_RESOURCE:
			$Worker.carry_from_pile(_target_pile)
			_target_pile = null
			$Worker.navigate_to($Worker.home_world_pos())
			_state = State.GO_HOME
		State.GO_HOME:
			$Worker.drop().queue_free()
			_state = State.WORK
			_work_elapsed = 0.0
		State.GO_HOME_TO_WORK:
			_state = State.WORK
			_work_elapsed = 0.0

func _do_work(delta: float) -> void:
	_work_elapsed += delta * 1000.0
	if _work_elapsed >= Constants.mill_work_duration_ms:
		if $Worker.is_output_full(_output_pile):
			return
		_output_pile.add_resource(_output_scene)
		_state = State.WAIT_FOR_RESOURCE
		_coordination_manager.queue_resource_collection(self, _input_resource_type)
