class_name CoordinationManager
extends Node

enum ResourceType { LOG, PLANK, APPLE }

var _builders: Array = []
var _buildings: Array = []
var _construction_queue: Array = []
var _resource_queues: Dictionary = {}

func _ready() -> void:
	_resource_queues[ResourceType.LOG] = []
	_resource_queues[ResourceType.PLANK] = []
	_resource_queues[ResourceType.APPLE] = []

# --- Builder / building registration ---

func register_builder(builder: Builder) -> void:
	_builders.append(builder)
	notify_idle_builder(builder)

func register_building(building: Node2D) -> void:
	_buildings.append(building)

# --- Construction queue ---

func queue_construction(target: Building) -> void:
	var builder := _find_closest_free_builder(target.position)
	if builder != null:
		builder.assign_build_task(target)
	else:
		_construction_queue.append(target)

func notify_idle_builder(builder: Builder) -> void:
	if _construction_queue.is_empty():
		return
	var idx := _find_closest_construction_idx(builder.position)
	var target := _construction_queue[idx] as Building
	_construction_queue.remove_at(idx)
	builder.assign_build_task(target)

# --- Resource collection queue ---

func queue_resource_collection(worker: ResourceCollectorWorker, resource_type: int) -> void:
	var pile := _find_free_resource_pile(resource_type)
	if pile != null:
		pile.reserve(worker)
		worker.go_collect_resource(pile)
	else:
		_resource_queues[resource_type].append(worker)

func notify_free_resource(resource_type: int) -> void:
	var queue: Array = _resource_queues[resource_type]
	if queue.is_empty():
		return
	var pile := _find_free_resource_pile(resource_type)
	if pile == null:
		return
	var worker = queue.pop_front()
	pile.reserve(worker)
	worker.go_collect_resource(pile)

func _find_free_resource_pile(resource_type: int) -> ResourcePile:
	for building in _buildings:
		var pile := _get_pile_for_type(building as Node2D, resource_type)
		if pile != null and pile.free_count() > 0:
			return pile
	return null

func _get_pile_for_type(building: Node2D, resource_type: int) -> ResourcePile:
	match resource_type:
		ResourceType.LOG:
			if building is WoodcutterHut:
				return building.get_node_or_null("OutputPile") as ResourcePile
		ResourceType.PLANK:
			if building is Sawmill or building is BuilderHut:
				return building.get_node_or_null("OutputPile") as ResourcePile
		ResourceType.APPLE:
			if building is AppleFarm:
				return building.get_node_or_null("OutputPile") as ResourcePile
	return null

# --- Private helpers ---

func _find_closest_free_builder(pos: Vector2) -> Builder:
	var closest: Builder = null
	var min_dist := INF
	for b in _builders:
		var builder := b as Builder
		if builder != null and builder.is_free():
			var d := builder.position.distance_to(pos)
			if d < min_dist:
				min_dist = d
				closest = builder
	return closest

func _find_closest_construction_idx(pos: Vector2) -> int:
	var best_idx := 0
	var min_dist := INF
	for i in _construction_queue.size():
		var building := _construction_queue[i] as Building
		if building != null:
			var d := building.position.distance_to(pos)
			if d < min_dist:
				min_dist = d
				best_idx = i
	return best_idx
