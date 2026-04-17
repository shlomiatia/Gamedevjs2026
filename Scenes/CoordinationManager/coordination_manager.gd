class_name CoordinationManager
extends Node

signal game_over

enum ResourceType { LOG, PLANK, APPLE, CIDER, WOOL, CLOTHES }

var _builders: Array = []
var _buildings: Array = []
var _construction_queue: Array = []
var _resource_queues: Dictionary = {}
var _food_queue: Array = []
var _drink_queue: Array = []
var _clothing_queue: Array = []

func _ready() -> void:
	_resource_queues[ResourceType.LOG] = []
	_resource_queues[ResourceType.PLANK] = []
	_resource_queues[ResourceType.APPLE] = []
	_resource_queues[ResourceType.CIDER] = []
	_resource_queues[ResourceType.WOOL] = []
	_resource_queues[ResourceType.CLOTHES] = []

# --- Builder / building registration ---

func register_builder(builder: Builder) -> void:
	_builders.append(builder)
	notify_idle_builder(builder)

func deregister_builder(builder: Builder) -> void:
	_builders.erase(builder)
	if _builders.is_empty():
		game_over.emit()

func register_building(building: Node2D) -> void:
	_buildings.append(building)

# --- Construction queue ---

func queue_construction(target: Node2D) -> void:
	var builder := _find_closest_free_builder(target.position)
	if builder != null:
		builder.assign_build_task(target)
	else:
		_construction_queue.append(target)

func notify_idle_builder(builder: Builder) -> void:
	if _construction_queue.is_empty():
		return
	var target = _construction_queue.pop_front()
	builder.assign_build_task(target)

# --- Resource collection queue ---

func queue_resource_collection(worker: ResourceCollectorWorker, resource_type: int) -> void:
	var pile := _find_free_resource_pile(resource_type)
	if pile != null:
		pile.reserve(worker)
		worker.go_collect_resource(pile)
	else:
		_resource_queues[resource_type].append(worker)

func queue_food_collection(worker: Node2D) -> void:
	var pile := _find_nearest_food_pile(worker.position)
	if pile != null:
		pile.reserve(worker)
		worker.go_eat_food(pile)
	else:
		_food_queue.append(worker)

func queue_drink_collection(worker: Node2D) -> void:
	var pile := _find_nearest_drink_pile(worker.position)
	if pile != null:
		pile.reserve(worker)
		worker.go_drink_cider(pile)
	else:
		_drink_queue.append(worker)

func queue_clothing_collection(worker: Node2D) -> void:
	var pile := _find_nearest_clothing_pile(worker.position)
	if pile != null:
		pile.reserve(worker)
		worker.go_wear_clothes(pile)
	else:
		_clothing_queue.append(worker)

func notify_free_resource(resource_type: int) -> void:
	if resource_type == ResourceType.APPLE:
		_cleanup_food_queue()
		if not _food_queue.is_empty():
			_food_queue.sort_custom(func(a, b):
				var ha: float = (a.get_node("Worker") as Worker).hunger
				var hb: float = (b.get_node("Worker") as Worker).hunger
				return ha < hb
			)
			var hungry_worker := _food_queue.pop_front() as Node2D
			var pile := _find_nearest_food_pile(hungry_worker.position)
			if pile != null:
				pile.reserve(hungry_worker)
				hungry_worker.go_eat_food(pile)
				return
			else:
				_food_queue.push_front(hungry_worker)
				return
	if resource_type == ResourceType.CIDER:
		_cleanup_drink_queue()
		if not _drink_queue.is_empty():
			_drink_queue.sort_custom(func(a, b):
				var ta: float = (a.get_node("Worker") as Worker).thirst
				var tb: float = (b.get_node("Worker") as Worker).thirst
				return ta < tb
			)
			var thirsty_worker := _drink_queue.pop_front() as Node2D
			var pile := _find_nearest_drink_pile(thirsty_worker.position)
			if pile != null:
				pile.reserve(thirsty_worker)
				thirsty_worker.go_drink_cider(pile)
				return
			else:
				_drink_queue.push_front(thirsty_worker)
				return
	if resource_type == ResourceType.CLOTHES:
		_cleanup_clothing_queue()
		if not _clothing_queue.is_empty():
			_clothing_queue.sort_custom(func(a, b):
				var ca: float = (a.get_node("Worker") as Worker).clothing
				var cb: float = (b.get_node("Worker") as Worker).clothing
				return ca < cb
			)
			var needy_worker := _clothing_queue.pop_front() as Node2D
			var pile := _find_nearest_clothing_pile(needy_worker.position)
			if pile != null:
				pile.reserve(needy_worker)
				needy_worker.go_wear_clothes(pile)
				return
			else:
				_clothing_queue.push_front(needy_worker)
				return
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
				return building.get_node_or_null("Building/OutputPile") as ResourcePile
		ResourceType.PLANK:
			if building is Sawmill or building is BuilderHut:
				return building.get_node_or_null("Building/OutputPile") as ResourcePile
		ResourceType.APPLE:
			if building is AppleFarm:
				return building.get_node_or_null("Building/OutputPile") as ResourcePile
		ResourceType.CIDER:
			if building is CiderMill:
				return building.get_node_or_null("Building/OutputPile") as ResourcePile
		ResourceType.WOOL:
			if building is SheepFarm:
				return building.get_node_or_null("Building/OutputPile") as ResourcePile
		ResourceType.CLOTHES:
			if building is WoolMill:
				return building.get_node_or_null("Building/OutputPile") as ResourcePile
	return null

func _find_nearest_drink_pile(from_pos: Vector2) -> ResourcePile:
	var best: ResourcePile = null
	var best_dist := INF
	for building in _buildings:
		var pile := _get_pile_for_type(building as Node2D, ResourceType.CIDER)
		if pile != null and pile.free_count() > 0:
			var d := (building as Node2D).position.distance_to(from_pos)
			if d < best_dist:
				best_dist = d
				best = pile
	return best

func _cleanup_drink_queue() -> void:
	_drink_queue = _drink_queue.filter(func(w): return is_instance_valid(w))

func _find_nearest_clothing_pile(from_pos: Vector2) -> ResourcePile:
	var best: ResourcePile = null
	var best_dist := INF
	for building in _buildings:
		var pile := _get_pile_for_type(building as Node2D, ResourceType.CLOTHES)
		if pile != null and pile.free_count() > 0:
			var d := (building as Node2D).position.distance_to(from_pos)
			if d < best_dist:
				best_dist = d
				best = pile
	return best

func _cleanup_clothing_queue() -> void:
	_clothing_queue = _clothing_queue.filter(func(w): return is_instance_valid(w))

func _find_nearest_food_pile(from_pos: Vector2) -> ResourcePile:
	var best: ResourcePile = null
	var best_dist := INF
	for building in _buildings:
		var pile := _get_pile_for_type(building as Node2D, ResourceType.APPLE)
		if pile != null and pile.free_count() > 0:
			var d := (building as Node2D).position.distance_to(from_pos)
			if d < best_dist:
				best_dist = d
				best = pile
	return best

func _cleanup_food_queue() -> void:
	_food_queue = _food_queue.filter(func(w): return is_instance_valid(w))

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

