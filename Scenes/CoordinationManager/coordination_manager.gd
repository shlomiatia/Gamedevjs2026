class_name CoordinationManager
extends Node

signal game_over
signal game_won
signal worker_registered(count: int)
signal worker_became_hungry
signal construction_queued

const WIN_WORKER_COUNT := 30

enum ResourceType {LOG, PLANK, APPLE, CIDER, WOOL, CLOTHES, CLAY, BRICK, COAL, IRON_ORE, IRON_BAR, TOOL, MILK, CHEESE, WHEAT, FLOUR, BREAD, BEER}

const RESOURCE_TO_NEED := {
    ResourceType.APPLE: Worker.NeedType.FOOD,
    ResourceType.CHEESE: Worker.NeedType.FOOD,
    ResourceType.BREAD: Worker.NeedType.FOOD,
    ResourceType.CIDER: Worker.NeedType.DRINK,
    ResourceType.MILK: Worker.NeedType.DRINK,
    ResourceType.BEER: Worker.NeedType.DRINK,
    ResourceType.CLOTHES: Worker.NeedType.CLOTHING,
    ResourceType.TOOL: Worker.NeedType.TOOL,
}

const NEED_TO_RESOURCE := {
    Worker.NeedType.FOOD: [ResourceType.APPLE, ResourceType.CHEESE, ResourceType.BREAD],
    Worker.NeedType.DRINK: [ResourceType.CIDER, ResourceType.MILK, ResourceType.BEER],
    Worker.NeedType.CLOTHING: [ResourceType.CLOTHES],
    Worker.NeedType.TOOL: [ResourceType.TOOL],
}

func get_satisfaction_for_resource(resource_type: int) -> float:
    match resource_type:
        ResourceType.APPLE: return Constants.apple_satisfaction
        ResourceType.CHEESE: return Constants.cheese_satisfaction
        ResourceType.BREAD: return Constants.bread_satisfaction
        ResourceType.MILK: return Constants.milk_satisfaction
        ResourceType.CIDER: return Constants.cider_satisfaction
        ResourceType.BEER: return Constants.beer_satisfaction
        ResourceType.CLOTHES: return Constants.clothes_satisfaction
        ResourceType.TOOL: return Constants.tool_satisfaction
    return Constants.initial_hunger

var _builders: Array = []
var all_workers: Array = []
var _dead_count: int = 0
var buildings: Array = []
var _construction_queue: Array = []
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

func get_site_count_by_resource() -> Dictionary:
    # Initialize your counts
    var counts = {
        ResourceType.PLANK: 0,
        ResourceType.BRICK: 0
    }

    for b in _construction_queue:
        var res_type = b.get("CONSTRUCTION_RESOURCE_TYPE")
        if res_type == null:
            res_type = ResourceType.PLANK

        if counts.has(res_type):
            counts[res_type] += 1

    for b in _builders:
        var builder := b as Builder
        if builder != null and not builder.is_free():
            var res_type = builder._build_res_type
            if counts.has(res_type):
                counts[res_type] += 1
            
    return counts

func register_builder(builder: Builder) -> void:
    _builders.append(builder)
    notify_idle_builder(builder)

func deregister_builder(builder: Builder) -> void:
    _builders.erase(builder)
    if _builders.is_empty():
        game_over.emit()

func register_worker(worker_node: Node2D) -> void:
    all_workers.append(worker_node)
    worker_registered.emit(all_workers.size())
    if all_workers.size() >= WIN_WORKER_COUNT:
        game_won.emit()

func deregister_worker(worker_node: Node2D) -> void:
    all_workers.erase(worker_node)
    _dead_count += 1

func register_building(building: Node2D) -> void:
    buildings.append(building)

# --- Construction queue ---

var _hungry_signal_emitted := false

func queue_construction(target: Node2D) -> void:
    construction_queued.emit()
    var builder := _find_closest_free_builder(target.position)
    if builder != null:
        builder.assign_build_task(target)
    else:
        _construction_queue.append(target)

func cancel_construction(target: Node2D) -> void:
    if target in _construction_queue:
        _construction_queue.erase(target)
        buildings.erase(target)

func notify_idle_builder(builder: Builder) -> void:
    if _construction_queue.is_empty():
        return
    var target = _construction_queue.pop_front()
    builder.assign_build_task(target)

# --- Resource collection ---

func queue_resource_collection(worker: Node2D, resource_type: int) -> void:
    var pile := _find_free_resource_pile(resource_type, worker.position)
    if pile != null:
        pile.reserve(worker)
        worker.go_collect_resource(pile)
    else:
        _resource_queues[resource_type].append(worker)

func queue_need_collection(worker: Node2D, need: int) -> void:
    if need == Worker.NeedType.FOOD and not _hungry_signal_emitted:
        _hungry_signal_emitted = true
        worker_became_hungry.emit()
    var result := _find_nearest_pile_for_need(need, worker.position)
    var pile: ResourcePile = result[0]
    var resource_type: int = result[1]
    if pile != null:
        pile.reserve(worker)
        (worker.get_node("Worker") as Worker).handle_need(need, pile, resource_type)
    else:
        _need_queues[need].append(worker)

func notify_free_resource(resource_type: int, pile: ResourcePile) -> void:
    if RESOURCE_TO_NEED.has(resource_type):
        _dispatch_need_queue(RESOURCE_TO_NEED[resource_type], pile, resource_type)
    if pile.free_count() == 0:
        return
    _cleanup_resource_queue(resource_type)
    var queue: Array = _resource_queues[resource_type]
    if queue.is_empty():
        return
    var worker = queue.pop_front()
    pile.reserve(worker)
    worker.go_collect_resource(pile)

func _cleanup_resource_queue(resource_type: int) -> void:
    _resource_queues[resource_type] = _resource_queues[resource_type].filter(func(w): return is_instance_valid(w))

func _dispatch_need_queue(need: int, pile: ResourcePile, resource_type: int) -> void:
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
    (best.get_node("Worker") as Worker).handle_need(need, pile, resource_type)

func _cleanup_need_queue(need: int) -> void:
    _need_queues[need] = _need_queues[need].filter(func(w): return is_instance_valid(w))

func _find_free_resource_pile(resource_type: int, from_pos: Vector2) -> ResourcePile:
    var best: ResourcePile = null
    var best_dist := INF
    for building in buildings:
        var pile: ResourcePile = building.get_pile_for_type(resource_type)
        if pile != null and pile.free_count() > 0:
            var d: float = (building as Node2D).position.distance_to(from_pos)
            if d < best_dist:
                best_dist = d
                best = pile
    return best

func _find_nearest_pile_for_need(need: int, from_pos: Vector2) -> Array:
    var resource_types: Array = NEED_TO_RESOURCE[need]
    var best: ResourcePile = null
    var best_type: int = -1
    var best_dist := INF
    for rt: int in resource_types:
        for building in buildings:
            var pile: ResourcePile = building.get_pile_for_type(rt)
            if pile != null and pile.free_count() > 0:
                var d: float = (building as Node2D).position.distance_to(from_pos)
                if d < best_dist:
                    best_dist = d
                    best = pile
                    best_type = rt
    return [best, best_type]

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
