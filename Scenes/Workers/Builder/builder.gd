class_name Builder
extends ResourceCollectorWorker

const BUILD_DURATION_MS := 5000.0

enum State { IDLE, WAIT_FOR_RESOURCE, GO_TO_RESOURCE, GO_TO_SITE, BUILD, GO_HOME }

var _state := State.IDLE
var _target_hut: Building = null
var _home_hut: Node2D = null
var _map: Map = null
var _build_elapsed := 0.0

func setup(home_hut: Node2D, map: Map, coordination_manager: Node) -> void:
	_home_hut = home_hut
	_map = map
	_coordination_manager = coordination_manager
	$Worker.setup(home_hut, map)
	coordination_manager.register_builder(self)
	$Worker.died.connect(func():
		_coordination_manager.deregister_builder(self)
		(_home_hut as Building).on_worker_died()
		queue_free()
	)

func is_free() -> bool:
	return _state == State.IDLE or _state == State.GO_HOME

func assign_build_task(target: Building) -> void:
	if not is_free():
		return
	_target_hut = target
	_state = State.WAIT_FOR_RESOURCE
	_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.PLANK)

func _set_collecting_state() -> void:
	_state = State.GO_TO_RESOURCE

func _process(delta: float) -> void:
	match _state:
		State.GO_TO_RESOURCE, State.GO_TO_SITE, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.BUILD:
			_do_build(delta)

func _site_world_pos() -> Vector2:
	return _target_hut.position + Vector2(0, float(_map.get_tile_size().y) * 0.5)

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_RESOURCE:
			_do_collect()
		State.GO_TO_SITE:
			_state = State.BUILD
			_build_elapsed = 0.0
		State.GO_HOME:
			_state = State.IDLE
			_coordination_manager.notify_idle_builder(self)

func _do_collect() -> void:
	var resource := _target_pile.collect(self)
	_target_pile = null
	if resource == null:
		_state = State.WAIT_FOR_RESOURCE
		_coordination_manager.queue_resource_collection(self, CoordinationManager.ResourceType.PLANK)
		return
	$Worker.carry(resource)
	$Worker.navigate_to(_site_world_pos())
	_state = State.GO_TO_SITE

func _do_build(delta: float) -> void:
	_build_elapsed += delta * 1000.0
	var progress: float = clampf(_build_elapsed / BUILD_DURATION_MS, 0.0, 1.0)
	_target_hut.set_construction_progress(progress)
	if progress >= 1.0:
		_finish_build()

func _finish_build() -> void:
	var resource: Node2D = $Worker.drop()
	if resource:
		resource.queue_free()
	_target_hut.complete_construction()
	_target_hut = null
	_state = State.GO_HOME
	$Worker.navigate_to($Worker.home_world_pos())
