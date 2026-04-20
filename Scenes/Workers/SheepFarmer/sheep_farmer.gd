class_name SheepFarmer
extends Node2D

const WoolScene = preload("res://Scenes/Resources/Wool/Wool.tscn")
const SheepScene = preload("res://Scenes/Sheep/Sheep.tscn")
const MilkScene = preload("res://Scenes/Resources/Milk/Milk.tscn")

enum State { IDLE, GO_TO_NEXT_TILE, GRAZE, GO_HOME, SHEAR }

var _state := State.IDLE
var _sheep_farm: SheepFarm = null
var _map: Map = null
var _spawn_parent: Node2D = null
var _herd: Array[Sheep] = []
var _wool_pile: ResourcePile = null
var _milk_pile: ResourcePile = null

var _pending_deliveries: Array = []
var _graze_tiles: Array[Vector2i] = []
var _delivered_sheep: Dictionary = {}

var _action_elapsed := 0.0
var _shear_elapsed := 0.0
var _shear_queue: Array = []  # Array of {sheep: Sheep, is_milk: bool}
var _spawn_new_sheep := false
var _first_return_done := false

func setup(sheep_farm: SheepFarm, map: Map, sheep: Sheep, spawn_parent: Node2D,
		coordination_manager: Node, wool_pile: ResourcePile, milk_pile: ResourcePile) -> void:
	_sheep_farm = sheep_farm
	_map = map
	_spawn_parent = spawn_parent
	_herd.append(sheep)
	_wool_pile = wool_pile
	_milk_pile = milk_pile
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
	$Worker.set_working(_state == State.SHEAR)
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

func _should_go_out() -> bool:
	if not _first_return_done:
		return true
	if _herd.size() < Constants.max_herd_size:
		return true
	var wool_full: bool = $Worker.is_output_full(_wool_pile, Constants.output_pile_capacity)
	var milk_full: bool = $Worker.is_output_full(_milk_pile, Constants.output_pile_capacity)
	return not (wool_full and milk_full)

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
	for sheep: Sheep in _herd:
		sheep.reset_follow_delay()
	$Worker.navigate_to(_map.tile_to_world((_pending_deliveries[0] as Dictionary).tile))
	_state = State.GO_TO_NEXT_TILE

func _follow_undelivered(_delta: float) -> void:
	for sheep: Sheep in _herd:
		if not _delivered_sheep.has(sheep):
			sheep.set_follow_target(global_position)

func _follow_all_sheep(_delta: float) -> void:
	for sheep: Sheep in _herd:
		sheep.set_follow_target(global_position)

func _on_arrived_at_tile() -> void:
	var delivery := _pending_deliveries.pop_front() as Dictionary
	var sheep := delivery.sheep as Sheep
	var tile := delivery.tile as Vector2i
	_graze_tiles.append(tile)
	_delivered_sheep[sheep] = true
	sheep.stop()
	if not _pending_deliveries.is_empty():
		$Worker.navigate_to(_map.tile_to_world((_pending_deliveries[0] as Dictionary).tile))
	else:
		_action_elapsed = 0.0
		for s: Sheep in _herd:
			s.set_eating(true)
		_state = State.GRAZE

func _finish_graze() -> void:
	for tile in _graze_tiles:
		_map.eat_grass(tile)
	for sheep: Sheep in _herd:
		sheep.set_eating(false)
		sheep.regrow()
		sheep.reset_follow_delay()
	_delivered_sheep.clear()
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME

func _on_arrived_home() -> void:
	for sheep: Sheep in _herd:
		sheep.stop()
	if _shear_queue.is_empty():
		_setup_shear_cycle()
	if not _shear_queue.is_empty():
		_shear_elapsed = 0.0
		_state = State.SHEAR
	else:
		_do_spawn_if_needed()

func _setup_shear_cycle() -> void:
	_shear_queue.clear()
	var to_process: Array[Sheep] = []

	if not _first_return_done:
		to_process = _herd.duplicate()
		_spawn_new_sheep = false
		_first_return_done = true
	elif _herd.size() < Constants.max_herd_size:
		for i in _herd.size() - 1:
			to_process.append(_herd[i])
		_spawn_new_sheep = true
	else:
		to_process = _herd.duplicate()
		_spawn_new_sheep = false

	_split_into_shear_queue(to_process)

func _split_into_shear_queue(sheep_list: Array[Sheep]) -> void:
	var n := sheep_list.size()
	var half := n / 2
	for i in half:
		_shear_queue.append({sheep = sheep_list[i], is_milk = false})
	for i in half:
		_shear_queue.append({sheep = sheep_list[half + i], is_milk = true})
	if n % 2 == 1:
		_shear_queue.append({sheep = sheep_list[n - 1], is_milk = randi() % 2 == 1})

func _do_shear(delta: float) -> void:
	_shear_elapsed += delta * 1000.0
	if _shear_elapsed < Constants.sheep_shear_time_ms:
		return
	_shear_elapsed = 0.0
	var entry := _shear_queue.pop_front() as Dictionary
	var sheep := entry.sheep as Sheep
	var is_milk: bool = entry.get("is_milk", false)
	if is_milk:
		if not $Worker.is_output_full(_milk_pile, Constants.output_pile_capacity):
			_milk_pile.add_resource(MilkScene)
	else:
		if not $Worker.is_output_full(_wool_pile, Constants.output_pile_capacity):
			_wool_pile.add_resource(WoolScene)
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
