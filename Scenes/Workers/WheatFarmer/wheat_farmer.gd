class_name WheatFarmer
extends Node2D

const WheatScene = preload("res://Scenes/Resources/Wheat/Wheat.tscn")

enum State { IDLE, GO_TO_PLANT, PLANT, GO_TO_HARVEST, HARVEST, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _wheat_farm: Node2D = null
var _map: Map = null
var _output_pile: ResourcePile = null
var _target_tile := Vector2i(-1, -1)
var _action_elapsed := 0.0
var _my_tiles: Dictionary = {}

func setup(wheat_farm: Node2D, map: Map, coordination_manager: Node, output_pile: ResourcePile) -> void:
	_wheat_farm = wheat_farm
	_map = map
	_output_pile = output_pile
	$Worker.setup(wheat_farm, map, coordination_manager)
	$Worker.display_name = "Wheat Farmer"

func resume_work() -> void:
	match _state:
		State.GO_TO_PLANT, State.GO_TO_HARVEST:
			$Worker.navigate_to(_map.tile_to_world(_target_tile))
		State.GO_HOME, State.DEPOSIT:
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.PLANT or _state == State.HARVEST)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.IDLE:
			_try_find_work()
		State.GO_TO_PLANT, State.GO_TO_HARVEST, State.GO_HOME, State.DEPOSIT:
			if $Worker.tick_movement(delta):
				_on_arrived()
		State.PLANT:
			_action_elapsed += delta * 1000.0
			if _action_elapsed >= Constants.wheat_plant_time_ms:
				_state = State.IDLE
		State.HARVEST:
			_action_elapsed += delta * 1000.0
			if _action_elapsed >= Constants.wheat_harvest_time_ms:
				_finish_harvest()

func _try_find_work() -> void:
	if not $Worker.is_output_full(_output_pile):
		var ready_tile := _find_my_ready_tile()
		if ready_tile != Vector2i(-1, -1):
			_target_tile = ready_tile
			_map.wheat.start_wheat_harvest_tween(_target_tile, Constants.wheat_harvest_time_ms / 1000.0)
			$Worker.navigate_to(_map.tile_to_world(_target_tile))
			_state = State.GO_TO_HARVEST
			return
	if $Worker.is_output_full(_output_pile):
		return
	var tile := _map.wheat.find_wheat_planting_tile(_wheat_farm.position)
	if tile == Vector2i(-1, -1):
		return
	_target_tile = tile
	_my_tiles[tile] = true
	_map.occupied_tiles[tile] = Map.OccupiedType.BLOCK_BUILDING
	_map.wheat.plant_wheat(tile, Constants.wheat_grow_time_ms / 1000.0)
	$Worker.navigate_to(_map.tile_to_world(tile))
	_state = State.GO_TO_PLANT

func _find_my_ready_tile() -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for tile: Vector2i in _my_tiles:
		if _map.wheat.is_wheat_ready(tile):
			var dist := _wheat_farm.position.distance_to(_map.tile_to_world(tile))
			if dist < best_dist:
				best_dist = dist
				best = tile
	return best

func _on_arrived() -> void:
	_action_elapsed = 0.0
	match _state:
		State.GO_TO_PLANT:
			_state = State.PLANT
		State.GO_TO_HARVEST:
			_state = State.HARVEST
		State.GO_HOME:
			_state = State.DEPOSIT
		State.DEPOSIT:
			if $Worker.is_output_full(_output_pile):
				return
			_output_pile.add_existing_resource($Worker.drop())
			_target_tile = Vector2i(-1, -1)
			_state = State.IDLE

func _finish_harvest() -> void:
	_map.wheat.finish_wheat_harvest(_target_tile)
	$Worker.carry(WheatScene.instantiate() as Node2D)
	_my_tiles.erase(_target_tile)
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME
