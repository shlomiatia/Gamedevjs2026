class_name SheepFarmer
extends Node2D

const OUTPUT_PILE_CAPACITY := 8
const SHEEP_EAT_TIME := 4000.0
const SHEEP_SHEAR_TIME := 3000.0
const IDLE_CHECK_INTERVAL := 0.5

const WoolScene = preload("res://Scenes/Resources/Wool/Wool.tscn")

enum State { IDLE, GO_TO_GRASS, GRAZE, GO_HOME, SHEAR }

var _state := State.IDLE
var _sheep_farm: SheepFarm = null
var _map: Map = null
var _sheep: Sheep = null
var _target_tile := Vector2i(-1, -1)
var _action_elapsed := 0.0
var _idle_timer := 0.0

func setup(sheep_farm: SheepFarm, map: Map, sheep: Sheep, coordination_manager: Node) -> void:
    _sheep_farm = sheep_farm
    _map = map
    _sheep = sheep
    $Worker.setup(sheep_farm, map)
    $Worker.setup_food(coordination_manager)
    $Worker.died.connect(func():
        if _target_tile != Vector2i(-1, -1) and _map.occupied_tiles.get(_target_tile) == self:
            _map.occupied_tiles.erase(_target_tile)
        _sheep_farm.on_worker_died()
        queue_free()
    )

func go_eat_food(pile: ResourcePile) -> void:
    $Worker.go_eat_food(pile)

func go_drink_cider(pile: ResourcePile) -> void:
    $Worker.go_drink_cider(pile)

func _process(delta: float) -> void:
    $Worker.set_working(_state == State.GRAZE or _state == State.SHEAR)
    match _state:
        State.IDLE:
            if not $Worker.is_satisfying_need():
                _try_find_grass(delta)
        State.GO_TO_GRASS, State.GO_HOME:
            if $Worker.tick_movement(delta):
                _on_path_finished()
            elif is_instance_valid(_sheep):
                _sheep.follow_toward(position, delta)
        State.GRAZE:
            if not $Worker.is_satisfying_need():
                _action_elapsed += delta * 1000.0
                if _action_elapsed >= SHEEP_EAT_TIME:
                    _action_elapsed = 0.0
                    _finish_graze()
        State.SHEAR:
            if not $Worker.is_satisfying_need():
                _action_elapsed += delta * 1000.0
                if _action_elapsed >= SHEEP_SHEAR_TIME:
                    _action_elapsed = 0.0
                    _finish_shear()

func _is_output_full() -> bool:
    return $Worker.is_pile_full(_output_pile(), OUTPUT_PILE_CAPACITY)

func _try_find_grass(delta: float) -> void:
    _idle_timer -= delta
    if _idle_timer > 0.0:
        return
    _idle_timer = IDLE_CHECK_INTERVAL

    if _is_output_full():
        return

    var tile := _map.find_grass_tile(position)
    if tile == Vector2i(-1, -1):
        return

    _map.occupied_tiles[tile] = self
    _target_tile = tile
    $Worker.navigate_to(_map.tile_to_world(tile))
    _state = State.GO_TO_GRASS

func _finish_graze() -> void:
    _map.eat_grass(_target_tile)
    _target_tile = Vector2i(-1, -1)
    if is_instance_valid(_sheep):
        _sheep.regrow()
    $Worker.navigate_to($Worker.home_world_pos())
    _state = State.GO_HOME

func _finish_shear() -> void:
    if is_instance_valid(_sheep):
        _sheep.shear()
        _sheep.set_walking(false)
    _output_pile().add_resource(WoolScene)
    _state = State.IDLE

func _output_pile() -> ResourcePile:
    return _sheep_farm.get_node("Building/OutputPile") as ResourcePile

func _on_path_finished() -> void:
    if is_instance_valid(_sheep):
        _sheep.set_walking(false)
    match _state:
        State.GO_TO_GRASS:
            _state = State.GRAZE
            _action_elapsed = 0.0
        State.GO_HOME:
            _state = State.SHEAR
            _action_elapsed = 0.0
