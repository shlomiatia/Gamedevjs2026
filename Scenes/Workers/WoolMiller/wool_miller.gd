class_name WoolMiller
extends ResourceCollectorWorker

const WORK_DURATION_MS := 5000.0

const ClothesScene = preload("res://Scenes/Resources/Clothes/Clothes.tscn")

enum State { WAIT_FOR_RESOURCE, GO_TO_RESOURCE, GO_HOME, WORK }

var _state := State.WAIT_FOR_RESOURCE
var _wool_mill: WoolMill = null
var _map: Map = null
var _work_elapsed := 0.0

func setup(wool_mill: WoolMill, map: Map, coordination_manager: Node) -> void:
    _wool_mill = wool_mill
    _map = map
    _coordination_manager = coordination_manager
    $Worker.setup(wool_mill, map)
    $Worker.setup_food(coordination_manager)
    $Worker.died.connect(func():
        _wool_mill.on_worker_died()
        queue_free()
    )

func _ready() -> void:
    _coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.WOOL)

func _set_collecting_state() -> void:
    _state = State.GO_TO_RESOURCE

func go_eat_food(pile: ResourcePile) -> void:
    $Worker.go_eat_food(pile)

func go_drink_cider(pile: ResourcePile) -> void:
    $Worker.go_drink_cider(pile)

func _process(delta: float) -> void:
    var working: bool = _state == State.WORK and not $Worker.is_satisfying_need()
    $Worker.set_working(working)
    _wool_mill.set_milling(working)
    match _state:
        State.GO_TO_RESOURCE, State.GO_HOME:
            if $Worker.tick_movement(delta):
                _on_path_finished()
        State.WORK:
            if not $Worker.is_satisfying_need():
                _do_work(delta)

func _on_path_finished() -> void:
    match _state:
        State.GO_TO_RESOURCE:
            _do_collect()
        State.GO_HOME:
            _state = State.WORK
            _work_elapsed = 0.0

func _do_collect() -> void:
    var wool_node := _target_pile.collect(self)
    _target_pile = null
    if wool_node == null:
        _state = State.WAIT_FOR_RESOURCE
        _coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.WOOL)
        return
    $Worker.carry(wool_node)
    $Worker.navigate_to($Worker.home_world_pos())
    _state = State.GO_HOME

func _do_work(delta: float) -> void:
    _work_elapsed += delta * 1000.0
    if _work_elapsed >= WORK_DURATION_MS:
        _finish_work()

func _finish_work() -> void:
    var wool_node: Node2D = $Worker.drop()
    if wool_node:
        wool_node.queue_free()
    var output_pile := _wool_mill.get_node("Building/OutputPile") as ResourcePile
    output_pile.add_resource(ClothesScene)
    _state = State.WAIT_FOR_RESOURCE
    _coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.WOOL)
