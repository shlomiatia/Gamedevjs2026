class_name SheepFarmer
extends Node2D

const OUTPUT_PILE_CAPACITY := 8
const SHEEP_EAT_TIME := 4000.0
const SHEEP_SHEAR_TIME := 3000.0

const WoolScene = preload("res://Scenes/Resources/Wool/Wool.tscn")

enum State { IDLE, GO_TO_GRASS, GRAZE, GO_HOME, SHEAR }

var _state := State.IDLE
var _sheep_farm: SheepFarm = null
var _map: Map = null
var _sheep: Sheep = null
var _target_tile := Vector2i(-1, -1)
var _action_elapsed := 0.0

func setup(sheep_farm: SheepFarm, map: Map, sheep: Sheep, coordination_manager: Node) -> void:
	_sheep_farm = sheep_farm
	_map = map
	_sheep = sheep
	$Worker.setup(sheep_farm, map, coordination_manager)

func resume_work() -> void:
	match _state:
		State.GO_TO_GRASS, State.GRAZE:
			_state = State.GO_TO_GRASS
			$Worker.navigate_to(_map.tile_to_world(_target_tile))
		State.GO_HOME, State.SHEAR:
			_state = State.GO_HOME
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.GRAZE or _state == State.SHEAR)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.IDLE:
			_try_find_grass()
		State.GO_TO_GRASS, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
			elif is_instance_valid(_sheep):
				_sheep.follow_toward(position, delta)
		State.GRAZE:
			_action_elapsed += delta * 1000.0
			if _action_elapsed >= SHEEP_EAT_TIME:
				_action_elapsed = 0.0
				_finish_graze()
		State.SHEAR:
			_action_elapsed += delta * 1000.0
			if _action_elapsed >= SHEEP_SHEAR_TIME:
				_action_elapsed = 0.0
				_finish_shear()

func _output_pile() -> ResourcePile:
	return _sheep_farm.get_node("Building/OutputPile") as ResourcePile

func _try_find_grass() -> void:
	if $Worker.is_output_full(_output_pile(), OUTPUT_PILE_CAPACITY):
		return
	var tile := _map.find_grass_tile(position)
	if tile == Vector2i(-1, -1):
		return
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
