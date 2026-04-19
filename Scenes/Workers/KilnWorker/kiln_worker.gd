class_name KilnWorker
extends Node2D


enum State {
	WAIT_FOR_RES1, GO_TO_RES1, GO_HOME_WITH_RES1,
	WAIT_FOR_RES2, GO_TO_RES2, GO_HOME_WITH_RES2,
	WORK, GO_HOME_TO_WORK
}

var _state := State.WAIT_FOR_RES1
var _building: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _target_pile: ResourcePile = null
var _output_scene: PackedScene = null
var _output_pile: ResourcePile = null
var _resource_type_1: int = -1
var _resource_type_2: int = -1
var _work_elapsed := 0.0

func setup(building: Node2D, map: Map, coordination_manager: Node, output_scene: PackedScene, resource_type_1: int, resource_type_2: int, output_pile: ResourcePile) -> void:
	_building = building
	_map = map
	_coordination_manager = coordination_manager
	_output_scene = output_scene
	_output_pile = output_pile
	_resource_type_1 = resource_type_1
	_resource_type_2 = resource_type_2
	$Worker.setup(building, map, coordination_manager)

func _ready() -> void:
	_coordination_manager.queue_resource_collection(self, _resource_type_1)

func go_collect_resource(pile: ResourcePile) -> void:
	_target_pile = pile
	match _state:
		State.WAIT_FOR_RES1:
			_state = State.GO_TO_RES1
		State.WAIT_FOR_RES2:
			_state = State.GO_TO_RES2
	if not $Worker.is_satisfying_need():
		$Worker.navigate_to(pile.global_position)

func resume_work() -> void:
	match _state:
		State.GO_TO_RES1, State.GO_TO_RES2:
			$Worker.navigate_to(_target_pile.global_position)
		State.GO_HOME_WITH_RES1, State.GO_HOME_WITH_RES2, State.GO_HOME_TO_WORK:
			$Worker.navigate_to($Worker.home_world_pos())
		State.WORK:
			_state = State.GO_HOME_TO_WORK
			$Worker.navigate_to($Worker.home_world_pos())
		State.WAIT_FOR_RES1, State.WAIT_FOR_RES2:
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	var working := _state == State.WORK
	$Worker.set_working(working)
	if _building.has_method("set_smoking"):
		_building.set_smoking(working)
	(_building.get_node("Building") as BuildingComponent).set_milling(working)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.GO_TO_RES1, State.GO_TO_RES2, State.GO_HOME_WITH_RES1, State.GO_HOME_WITH_RES2, State.GO_HOME_TO_WORK:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.WORK:
			_do_work(delta)

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_RES1:
			$Worker.carry_from_pile(_target_pile)
			_target_pile = null
			_state = State.GO_HOME_WITH_RES1
			$Worker.navigate_to($Worker.home_world_pos())
		State.GO_HOME_WITH_RES1:
			$Worker.drop().queue_free()
			_state = State.WAIT_FOR_RES2
			_coordination_manager.queue_resource_collection(self, _resource_type_2)
		State.GO_TO_RES2:
			$Worker.carry_from_pile(_target_pile)
			_target_pile = null
			_state = State.GO_HOME_WITH_RES2
			$Worker.navigate_to($Worker.home_world_pos())
		State.GO_HOME_WITH_RES2:
			$Worker.drop().queue_free()
			_state = State.WORK
			_work_elapsed = 0.0
		State.GO_HOME_TO_WORK:
			_state = State.WORK

func _do_work(delta: float) -> void:
	_work_elapsed += delta * 1000.0
	if _work_elapsed >= Constants.kiln_work_duration_ms:
		_output_pile.add_resource(_output_scene)
		_state = State.WAIT_FOR_RES1
		_coordination_manager.queue_resource_collection(self, _resource_type_1)
