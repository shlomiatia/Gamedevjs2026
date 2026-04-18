class_name KilnWorker
extends Node2D

const WORK_DURATION_MS := 5000.0

enum State {
	WAIT_FOR_CLAY, GO_TO_CLAY, GO_HOME_WITH_CLAY,
	WAIT_FOR_LOG, GO_TO_LOG, GO_HOME_WITH_LOG,
	WORK, GO_HOME_TO_WORK
}

var _state := State.WAIT_FOR_CLAY
var _clay_kiln: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _target_pile: ResourcePile = null
var _output_scene: PackedScene = null
var _work_elapsed := 0.0

func setup(clay_kiln: Node2D, map: Map, coordination_manager: Node, output_scene: PackedScene) -> void:
	_clay_kiln = clay_kiln
	_map = map
	_coordination_manager = coordination_manager
	_output_scene = output_scene
	$Worker.setup(clay_kiln, map, coordination_manager)

func _ready() -> void:
	_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.CLAY)

func go_collect_resource(pile: ResourcePile) -> void:
	_target_pile = pile
	match _state:
		State.WAIT_FOR_CLAY:
			_state = State.GO_TO_CLAY
		State.WAIT_FOR_LOG:
			_state = State.GO_TO_LOG
	if not $Worker.is_satisfying_need():
		$Worker.navigate_to(pile.global_position)

func resume_work() -> void:
	match _state:
		State.GO_TO_CLAY, State.GO_TO_LOG:
			$Worker.navigate_to(_target_pile.global_position)
		State.GO_HOME_WITH_CLAY, State.GO_HOME_WITH_LOG, State.GO_HOME_TO_WORK:
			$Worker.navigate_to($Worker.home_world_pos())
		State.WORK:
			_state = State.GO_HOME_TO_WORK
			$Worker.navigate_to($Worker.home_world_pos())
		State.WAIT_FOR_CLAY, State.WAIT_FOR_LOG:
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	var working := _state == State.WORK
	$Worker.set_working(working)
	_clay_kiln.set_smoking(working)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.GO_TO_CLAY, State.GO_TO_LOG, State.GO_HOME_WITH_CLAY, State.GO_HOME_WITH_LOG, State.GO_HOME_TO_WORK:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.WORK:
			_do_work(delta)

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_CLAY:
			$Worker.carry_from_pile(_target_pile)
			_target_pile = null
			_state = State.GO_HOME_WITH_CLAY
			$Worker.navigate_to($Worker.home_world_pos())
		State.GO_HOME_WITH_CLAY:
			$Worker.drop().queue_free()
			_state = State.WAIT_FOR_LOG
			_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)
		State.GO_TO_LOG:
			$Worker.carry_from_pile(_target_pile)
			_target_pile = null
			_state = State.GO_HOME_WITH_LOG
			$Worker.navigate_to($Worker.home_world_pos())
		State.GO_HOME_WITH_LOG:
			$Worker.drop().queue_free()
			_state = State.WORK
			_work_elapsed = 0.0
		State.GO_HOME_TO_WORK:
			_state = State.WORK

func _do_work(delta: float) -> void:
	_work_elapsed += delta * 1000.0
	if _work_elapsed >= WORK_DURATION_MS:
		(_clay_kiln.get_node("Building/OutputPile") as ResourcePile).add_resource(_output_scene)
		_state = State.WAIT_FOR_CLAY
		_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.CLAY)
