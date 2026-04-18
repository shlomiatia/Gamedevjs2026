class_name Worker
extends Node2D

signal died

enum NeedType { FOOD = 0, DRINK = 1, CLOTHING = 2 }
const NO_NEED := -1

var _navigator: WorkerNavigator = null
var _needs: WorkerNeeds = null
var _backpack: WorkerBackpack = null

func setup(home: Node2D, map: Map, coordination_manager: Node) -> void:
    _navigator = $WorkerNavigator
    _needs = $WorkerNeeds
    _backpack = $WorkerBackpack
    _navigator.setup(get_parent(), home, map)
    _needs.setup(get_parent(), map, coordination_manager, _navigator)
    _backpack.setup(get_parent())
    _needs.died.connect(func():
        (home.get_node("Building") as BuildingComponent).on_worker_died()
        died.emit()
        get_parent().queue_free()
    )
    _needs.needs_satisfied.connect(func(): get_parent().resume_work())

func navigate_to(world_pos: Vector2) -> void:
    _navigator.navigate_to(world_pos)

func tick_movement(delta: float) -> bool:
    return _navigator.tick(delta)

func home_world_pos() -> Vector2:
    return _navigator.home_world_pos()

func is_satisfying_need() -> bool:
    return _needs.is_satisfying_need()

func handle_need(need: int, pile: ResourcePile) -> void:
    _needs.handle_need(need, pile)

func get_need_value(need: int) -> float:
    return _needs.get_need_value(need)

func set_working(val: bool) -> void:
    _needs.set_working(val)

func carry(resource: Node2D) -> void:
    _backpack.carry(resource)

func carry_from_pile(pile: ResourcePile) -> void:
    _backpack.carry_from_pile(pile, get_parent())

func drop() -> Node2D:
    return _backpack.drop()

func is_carrying() -> bool:
    return _backpack.is_carrying()

func is_output_full(pile: ResourcePile, capacity: int) -> bool:
    return pile.get_child_count() >= capacity
