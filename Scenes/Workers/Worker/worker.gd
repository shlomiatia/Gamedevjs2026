class_name Worker
extends Node2D

signal died

enum NeedType {FOOD = 0, DRINK = 1, CLOTHING = 2, TOOL = 3}
const NO_NEED := -1

var _navigator: WorkerNavigator = null
var _needs: WorkerNeeds = null
var _backpack: WorkerBackpack = null
var _anim: AnimatedSprite2D = null
var _working := false
var display_name: String = ""

func setup(home: Node2D, map: Map, coordination_manager: Node) -> void:
    _navigator = $WorkerNavigator
    _needs = $WorkerNeeds
    _backpack = $WorkerBackpack
    _anim = $AnimatedSprite2D
    _navigator.setup(get_parent(), home, map, $NavigationAgent2D)
    _needs.setup(get_parent(), map, coordination_manager, _navigator)
    _backpack.setup(get_parent())
    coordination_manager.register_worker(get_parent())
    _needs.died.connect(func():
        coordination_manager.deregister_worker(get_parent())
        (home.get_node("Building") as BuildingComponent).on_worker_died()
        died.emit()
        get_parent().queue_free()
    )
    _needs.needs_satisfied.connect(func(): get_parent().resume_work())
    _apply_building_colors(home)

func _apply_building_colors(home: Node2D) -> void:
    var sprite := home.get_node_or_null("Building/Sprite2D") as Sprite2D
    if sprite == null:
        return
    var building_mat := sprite.material as ShaderMaterial
    if building_mat == null:
        return
    var r0 = building_mat.get_shader_parameter("replace_0")
    if r0 == null:
        return
    var worker_mat := _anim.material.duplicate() as ShaderMaterial
    worker_mat.set_shader_parameter("replace_0", r0)
    worker_mat.set_shader_parameter("replace_1", building_mat.get_shader_parameter("replace_1"))
    worker_mat.set_shader_parameter("replace_2", building_mat.get_shader_parameter("replace_2"))
    _anim.material = worker_mat

func navigate_to(world_pos: Vector2) -> void:
    _navigator.navigate_to(world_pos)

func tick_movement(delta: float) -> bool:
    return _navigator.tick(delta)

func home_world_pos() -> Vector2:
    return _navigator.home_world_pos()

func is_satisfying_need() -> bool:
    return _needs.is_satisfying_need()

func handle_need(need: int, pile: ResourcePile, resource_type: int) -> void:
    _needs.handle_need(need, pile, resource_type)

func get_need_value(need: int) -> float:
    return _needs.get_need_value(need)

func set_working(val: bool) -> void:
    _working = val
    _needs.set_working(val)

func _process(_delta: float) -> void:
    if _navigator == null or _anim == null:
        return
    var facing := _navigator.get_facing()
    var prefix: String
    var flip := false
    if abs(facing.x) > abs(facing.y):
        prefix = "side"
        flip = facing.x < 0
    elif facing.y < 0:
        prefix = "up"
    else:
        prefix = "down"
    var suffix := "work" if (_working and not _needs.is_satisfying_need()) else ("walk" if _navigator.is_moving() else "stand")
    var anim_name := prefix + "_" + suffix
    if _anim.animation != anim_name:
        _anim.play(anim_name)
    _anim.flip_h = flip

func carry(resource: Node2D) -> void:
    _backpack.carry(resource)

func carry_from_pile(pile: ResourcePile) -> void:
    _backpack.carry_from_pile(pile, get_parent())

func drop() -> Node2D:
    return _backpack.drop()

func is_carrying() -> bool:
    return _backpack.is_carrying()

func is_output_full(pile: ResourcePile) -> bool:
    return pile.get_child_count() >= Constants.output_pile_capacity
