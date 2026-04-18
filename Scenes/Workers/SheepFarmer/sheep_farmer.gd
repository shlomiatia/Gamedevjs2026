class_name SheepFarmer
extends Node2D

const WoolScene = preload("res://Scenes/Resources/Wool/Wool.tscn")
const SheepScene = preload("res://Scenes/Sheep/Sheep.tscn")

enum State { IDLE, GO_TO_NEXT_TILE, GRAZE, GO_HOME, SHEAR }

var _state := State.IDLE
var _sheep_farm: SheepFarm = null
var _map: Map = null
var _spawn_parent: Node2D = null
var _herd: Array[Sheep] = []

var _pending_deliveries: Array = []   # Array of {sheep: Sheep, tile: Vector2i}
var _graze_tiles: Array[Vector2i] = []
var _delivered_sheep: Dictionary = {} # Sheep -> true

var _action_elapsed := 0.0
var _shear_elapsed := 0.0
var _shear_queue: Array = []          # Array of Sheep
var _spawn_new_sheep := false
var _first_return_done := false

func setup(sheep_farm: SheepFarm, map: Map, sheep: Sheep, spawn_parent: Node2D, coordination_manager: Node) -> void:
	_sheep_farm = sheep_farm
	_map = map
	_spawn_parent = spawn_parent
	_herd.append(sheep)
	$Worker.setup(sheep_farm, map, coordination_manager)

func resume_work() -> void:
	match _state:
		State.GO_TO_NEXT_TILE:
			if not _pending_deliveries.is_empty():
				$Worker.navigate_to(_map.tile_to_world((_pending_deliveries[0] as Dictionary).tile))
		State.GRAZE:
			pass
		State.GO_HOME, State.SHEAR:
			_state = State.GO_HOME
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.GRAZE or _state == State.SHEAR)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.IDLE:
			_try_find_tiles()
		State.GO_TO_NEXT_TILE:
			_follow_undelivered(delta)
			if $Worker.tick_movement(delta):
				_on_arrived_at_tile()
		State.GRAZE:
			_action_elapsed += delta * 1000.0
			if _action_elapsed >= Constants.sheep_eat_time_ms:
				_finish_graze()
		State.GO_HOME:
			_follow_all_sheep(delta)
			if $Worker.tick_movement(delta):
				_on_arrived_home()
		State.SHEAR:
			_do_shear(delta)

func _output_pile() -> ResourcePile:
	return _sheep_farm.get_node("Building/OutputPile") as ResourcePile

func _should_go_out() -> bool:
	if not _first_return_done:
		return true
	if _herd.size() < Constants.max_herd_size:
		return true
	return not $Worker.is_output_full(_output_pile(), Constants.output_pile_capacity)

func _try_find_tiles() -> void:
	if not _should_go_out():
		return
	var reserved: Dictionary = {}
	var deliveries: Array = []
	for sheep: Sheep in _herd:
		var tile := _map.find_grass_tile(_sheep_farm.position, reserved)
		if tile == Vector2i(-1, -1):
			return
		reserved[tile] = true
		deliveries.append({sheep = sheep, tile = tile})
	_pending_deliveries = deliveries
	_graze_tiles.clear()
	_delivered_sheep.clear()
	$Worker.navigate_to(_map.tile_to_world((_pending_deliveries[0] as Dictionary).tile))
	_state = State.GO_TO_NEXT_TILE

func _follow_undelivered(delta: float) -> void:
	for sheep: Sheep in _herd:
		if not _delivered_sheep.has(sheep):
			sheep.follow_toward(position, delta)

func _follow_all_sheep(delta: float) -> void:
	for sheep: Sheep in _herd:
		sheep.follow_toward(position, delta)

func _on_arrived_at_tile() -> void:
	var delivery := _pending_deliveries.pop_front() as Dictionary
	var sheep := delivery.sheep as Sheep
	var tile := delivery.tile as Vector2i
	_graze_tiles.append(tile)
	_delivered_sheep[sheep] = true
	sheep.set_walking(false)
	if not _pending_deliveries.is_empty():
		$Worker.navigate_to(_map.tile_to_world((_pending_deliveries[0] as Dictionary).tile))
	else:
		_action_elapsed = 0.0
		_state = State.GRAZE

func _finish_graze() -> void:
	for tile in _graze_tiles:
		_map.eat_grass(tile)
	for sheep: Sheep in _herd:
		sheep.regrow()
	_delivered_sheep.clear()
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME

func _on_arrived_home() -> void:
	for sheep: Sheep in _herd:
		sheep.set_walking(false)
	if _shear_queue.is_empty():
		_setup_shear_cycle()
	if not _shear_queue.is_empty():
		_shear_elapsed = 0.0
		_state = State.SHEAR
	else:
		_do_spawn_if_needed()

func _setup_shear_cycle() -> void:
	_shear_queue.clear()
	if not _first_return_done:
		for sheep in _herd:
			_shear_queue.append(sheep)
		_spawn_new_sheep = false
		_first_return_done = true
	elif _herd.size() < Constants.max_herd_size:
		for i in _herd.size() - 1:
			_shear_queue.append(_herd[i])
		_spawn_new_sheep = true
	else:
		for sheep in _herd:
			_shear_queue.append(sheep)
		_spawn_new_sheep = false

func _do_shear(delta: float) -> void:
	_shear_elapsed += delta * 1000.0
	if _shear_elapsed < Constants.sheep_shear_time_ms:
		return
	_shear_elapsed = 0.0
	var sheep := _shear_queue.pop_front() as Sheep
	if not $Worker.is_output_full(_output_pile(), Constants.output_pile_capacity):
		_output_pile().add_resource(WoolScene)
		sheep.shear()
	if _shear_queue.is_empty():
		_do_spawn_if_needed()

func _do_spawn_if_needed() -> void:
	if _spawn_new_sheep:
		_spawn_new_sheep = false
		var baby := SheepScene.instantiate() as Sheep
		baby.position = position
		_spawn_parent.add_child(baby)
		_herd.append(baby)
	_state = State.IDLE
