class_name CoordinationManager
extends Node

signal game_over

enum ResourceType { LOG, PLANK, APPLE, CIDER, WOOL, CLOTHES, CLAY, BRICK, COAL, IRON_ORE, IRON_BAR, TOOL }

const RESOURCE_TO_NEED := {
	ResourceType.APPLE: Worker.NeedType.FOOD,
	ResourceType.CIDER: Worker.NeedType.DRINK,
	ResourceType.CLOTHES: Worker.NeedType.CLOTHING,
	ResourceType.TOOL: Worker.NeedType.TOOL,
}

const NEED_TO_RESOURCE := {
	Worker.NeedType.FOOD: ResourceType.APPLE,
	Worker.NeedType.DRINK: ResourceType.CIDER,
	Worker.NeedType.CLOTHING: ResourceType.CLOTHES,
	Worker.NeedType.TOOL: ResourceType.TOOL,
}

var _builders: Array = []
var _all_workers: Array = []
var _dead_count: int = 0
var _buildings: Array = []
var _construction_queue: Array = []
var _active_constructions: int = 0
var _resource_queues: Dictionary = {}
var _need_queues: Dictionary = {}

func _ready() -> void:
	for type in ResourceType.values():
		_resource_queues[type] = []
	_need_queues[Worker.NeedType.FOOD] = []
	_need_queues[Worker.NeedType.DRINK] = []
	_need_queues[Worker.NeedType.CLOTHING] = []
	_need_queues[Worker.NeedType.TOOL] = []

# --- Builder / building registration ---

func register_builder(builder: Builder) -> void:
	_builders.append(builder)
	notify_idle_builder(builder)

func deregister_builder(builder: Builder) -> void:
	_builders.erase(builder)
	if _builders.is_empty():
		game_over.emit()

func register_worker(worker_node: Node2D) -> void:
	_all_workers.append(worker_node)

func deregister_worker(worker_node: Node2D) -> void:
	_all_workers.erase(worker_node)
	_dead_count += 1

func register_building(building: Node2D) -> void:
	_buildings.append(building)

func get_hud_stats() -> Dictionary:
	var hungry := 0
	var thirsty := 0
	var no_clothing := 0
	var no_tool := 0
	_all_workers = _all_workers.filter(func(w): return is_instance_valid(w))
	for entity in _all_workers:
		var wn := entity.get_node_or_null("Worker/WorkerNeeds") as WorkerNeeds
		if wn == null:
			continue
		if wn.hunger < Constants.hunger_threshold:
			hungry += 1
		if wn.thirst < Constants.thirst_threshold:
			thirsty += 1
		if wn.clothing == 0.0:
			no_clothing += 1
		if wn.get_need_value(Worker.NeedType.TOOL) == 0.0:
			no_tool += 1
	var res: Dictionary = {}
	for type in ResourceType.values():
		var total := 0
		for building in _buildings:
			var pile: ResourcePile = building.get_pile_for_type(type)
			if pile != null:
				total += pile.get_child_count()
		res[type] = total
	return {
		live_workers = _all_workers.size(),
		sites = _active_constructions,
		hungry = hungry,
		thirsty = thirsty,
		no_clothing = no_clothing,
		no_tool = no_tool,
		resources = res,
	}

# --- Construction queue ---

func queue_construction(target: Node2D) -> void:
	_active_constructions += 1
	var builder := _find_closest_free_builder(target.position)
	if builder != null:
		builder.assign_build_task(target)
	else:
		_construction_queue.append(target)

func notify_construction_complete() -> void:
	_active_constructions = maxi(0, _active_constructions - 1)

func notify_idle_builder(builder: Builder) -> void:
	if _construction_queue.is_empty():
		return
	var target = _construction_queue.pop_front()
	builder.assign_build_task(target)

# --- Resource collection ---

func queue_resource_collection(worker: Node2D, resource_type: int) -> void:
	var pile := _find_free_resource_pile(resource_type)
	if pile != null:
		pile.reserve(worker)
		worker.go_collect_resource(pile)
	else:
		_resource_queues[resource_type].append(worker)

func queue_need_collection(worker: Node2D, need: int) -> void:
	var pile := _find_nearest_pile_for_need(need, worker.position)
	if pile != null:
		pile.reserve(worker)
		(worker.get_node("Worker") as Worker).handle_need(need, pile)
	else:
		_need_queues[need].append(worker)

func notify_free_resource(resource_type: int, pile: ResourcePile) -> void:
	if RESOURCE_TO_NEED.has(resource_type):
		_dispatch_need_queue(RESOURCE_TO_NEED[resource_type], pile)
	if pile.free_count() == 0:
		return
	var queue: Array = _resource_queues[resource_type]
	if queue.is_empty():
		return
	var worker = queue.pop_front()
	pile.reserve(worker)
	worker.go_collect_resource(pile)

func _dispatch_need_queue(need: int, pile: ResourcePile) -> void:
	_cleanup_need_queue(need)
	var queue: Array = _need_queues[need]
	if queue.is_empty():
		return
	var best: Node2D = null
	var best_val := INF
	for w: Node2D in queue:
		var val: float = (w.get_node("Worker") as Worker).get_need_value(need)
		if val < best_val:
			best_val = val
			best = w
	queue.erase(best)
	pile.reserve(best)
	(best.get_node("Worker") as Worker).handle_need(need, pile)

func _cleanup_need_queue(need: int) -> void:
	_need_queues[need] = _need_queues[need].filter(func(w): return is_instance_valid(w))

func _find_free_resource_pile(resource_type: int) -> ResourcePile:
	for building in _buildings:
		var pile: ResourcePile = building.get_pile_for_type(resource_type)
		if pile != null and pile.free_count() > 0:
			return pile
	return null

func _find_nearest_pile_for_need(need: int, from_pos: Vector2) -> ResourcePile:
	var resource_type: int = NEED_TO_RESOURCE[need]
	var best: ResourcePile = null
	var best_dist := INF
	for building in _buildings:
		var pile: ResourcePile = building.get_pile_for_type(resource_type)
		if pile != null and pile.free_count() > 0:
			var d: float = (building as Node2D).position.distance_to(from_pos)
			if d < best_dist:
				best_dist = d
				best = pile
	return best

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
