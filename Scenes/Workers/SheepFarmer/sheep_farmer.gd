class_name SheepFarmer
extends Node2D

const OUTPUT_PILE_CAPACITY := 8
const IDLE_CHECK_INTERVAL := 0.5
const SHEAR_DURATION_MS := 3000.0

const WoolScene = preload("res://Scenes/Resources/Wool/Wool.tscn")

enum State { IDLE, GO_TO_SHEEP, SHEAR, GO_HOME, DEPOSIT }

var _state := State.IDLE
var _sheep_farm: SheepFarm = null
var _map: Map = null
var _target_sheep: Sheep = null
var _shear_elapsed := 0.0
var _idle_timer := 0.0

func setup(sheep_farm: SheepFarm, map: Map, coordination_manager: Node) -> void:
	_sheep_farm = sheep_farm
	_map = map
	$Worker.setup(sheep_farm, map)
	$Worker.setup_food(coordination_manager)
	$Worker.died.connect(func():
		_sheep_farm.on_worker_died()
		queue_free()
	)

func go_eat_food(pile: ResourcePile) -> void:
	$Worker.go_eat_food(pile)

func go_drink_cider(pile: ResourcePile) -> void:
	$Worker.go_drink_cider(pile)

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.SHEAR)
	match _state:
		State.IDLE:
			if not $Worker.is_satisfying_need():
				_try_find_sheep(delta)
		State.GO_TO_SHEEP, State.GO_HOME:
			if $Worker.tick_movement(delta):
				_on_path_finished()
		State.SHEAR:
			if not $Worker.is_satisfying_need():
				_do_shear(delta)
		State.DEPOSIT:
			if not $Worker.is_satisfying_need():
				_try_deposit()

func _output_pile() -> ResourcePile:
	return _sheep_farm.get_node("Building/OutputPile") as ResourcePile

func _is_output_full() -> bool:
	return $Worker.is_pile_full(_output_pile(), OUTPUT_PILE_CAPACITY)

func _try_find_sheep(delta: float) -> void:
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = IDLE_CHECK_INTERVAL

	if _is_output_full():
		return

	var sheep := _sheep_farm.find_unsheared_sheep()
	if sheep == null:
		return

	sheep.targeted = true
	_target_sheep = sheep
	$Worker.navigate_to(_target_sheep.position)
	_state = State.GO_TO_SHEEP

func _do_shear(delta: float) -> void:
	if not is_instance_valid(_target_sheep):
		_state = State.IDLE
		return
	_shear_elapsed += delta * 1000.0
	if _shear_elapsed >= SHEAR_DURATION_MS:
		_finish_shear()

func _finish_shear() -> void:
	_target_sheep.shear()
	_target_sheep.targeted = false
	_target_sheep = null
	$Worker.carry(WoolScene.instantiate() as Node2D)
	$Worker.navigate_to($Worker.home_world_pos())
	_state = State.GO_HOME

func _try_deposit() -> void:
	if _is_output_full():
		return
	_output_pile().add_existing_resource($Worker.drop())
	_state = State.IDLE

func _on_path_finished() -> void:
	match _state:
		State.GO_TO_SHEEP:
			_state = State.SHEAR
			_shear_elapsed = 0.0
		State.GO_HOME:
			_state = State.DEPOSIT
