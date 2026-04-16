class_name Sawmiller
extends ResourceCollectorWorker

const WORK_DURATION_MS := 5000.0

const PlankScene = preload("res://Scenes/Resources/Plank/Plank.tscn")

enum State { WAIT_FOR_RESOURCE, GO_TO_RESOURCE, GO_HOME, WORK }

var _state := State.WAIT_FOR_RESOURCE
var _sawmill: Sawmill = null
var _map: Map = null
var _work_elapsed := 0.0

func setup(sawmill: Sawmill, map: Map, coordination_manager: Node) -> void:
	_sawmill = sawmill
	_map = map
	_coordination_manager = coordination_manager
	$Worker.setup(sawmill, map)

func _ready() -> void:
	_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)

func _set_collecting_state() -> void:
	_state = State.GO_TO_RESOURCE

func _process(delta: float) -> void:
	match _state:
		State.GO_TO_RESOURCE, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.WORK:
			_do_work(delta)

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_RESOURCE:
			_do_collect()
		State.GO_HOME:
			_state = State.WORK
			_work_elapsed = 0.0

func _do_collect() -> void:
	var log_node := _target_pile.collect(self)
	_target_pile = null
	if log_node == null:
		_state = State.WAIT_FOR_RESOURCE
		_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)
		return
	$Worker.carry(log_node)
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME

func _do_work(delta: float) -> void:
	_work_elapsed += delta * 1000.0
	if _work_elapsed >= WORK_DURATION_MS:
		_finish_work()

func _finish_work() -> void:
	var log_node: Node2D = $Worker.drop()
	if log_node:
		log_node.queue_free()
	var output_pile := _sawmill.get_node("OutputPile") as ResourcePile
	output_pile.add_resource(PlankScene)
	_state = State.WAIT_FOR_RESOURCE
	_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.LOG)
