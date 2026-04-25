class_name Fisherman
extends Node2D

const RawFishScene = preload("res://Scenes/Resources/RawFish/RawFish.tscn")
const FISH_DURATION_MS := 5000.0

enum State {IDLE, GO_TO_RIVER, FISH, GO_HOME, DEPOSIT}

var _state := State.IDLE
var _fisherman_hut: Node2D = null
var _map: Map = null
var _output_pile: ResourcePile = null
var _fish_tile := Vector2i(-1, -1)
var _fish_elapsed := 0.0

func setup(fisherman_hut: Node2D, map: Map, coordination_manager: Node, output_pile: ResourcePile) -> void:
	_fisherman_hut = fisherman_hut
	_map = map
	_output_pile = output_pile
	$Worker.setup(fisherman_hut, map, coordination_manager)
	$Worker.display_name = FishermanHut.WORKER_NAME
	$Worker.set_uses_tools(false)

func _ready() -> void:
	_claim_next_tile()

func _claim_next_tile() -> void:
	_fish_tile = _find_fishing_tile()
	if _fish_tile != Vector2i(-1, -1):
		_map.visited_fish_tiles[_fish_tile] = true
		$Worker.navigate_to(_map.tile_to_world(_fish_tile))
		_state = State.GO_TO_RIVER

func resume_work() -> void:
	match _state:
		State.GO_TO_RIVER, State.FISH:
			if _fish_tile != Vector2i(-1, -1):
				$Worker.navigate_to(_map.tile_to_world(_fish_tile))
				_state = State.GO_TO_RIVER
		State.GO_HOME, State.DEPOSIT:
			$Worker.navigate_to($Worker.home_world_pos())

func _process(delta: float) -> void:
	$Worker.set_working(_state == State.FISH)
	if $Worker.is_satisfying_need():
		return
	match _state:
		State.IDLE:
			_claim_next_tile()
		State.GO_TO_RIVER, State.GO_HOME, State.DEPOSIT:
			if $Worker.tick_movement(delta):
				_on_arrived()
		State.FISH:
			_fish_elapsed += delta * 1000.0
			if _fish_elapsed >= FISH_DURATION_MS:
				_finish_fishing()

func _on_arrived() -> void:
	match _state:
		State.GO_TO_RIVER:
			_fish_elapsed = 0.0
			_state = State.FISH
		State.GO_HOME:
			_state = State.DEPOSIT
		State.DEPOSIT:
			if $Worker.is_output_full(_output_pile):
				return
			_output_pile.add_existing_resource($Worker.drop())
			_state = State.IDLE

func _finish_fishing() -> void:
	$Worker.carry(RawFishScene.instantiate() as Node2D)
	$Worker.navigate_to($Worker.home_world_pos())
	_fish_tile = Vector2i(-1, -1)
	_state = State.GO_HOME

func _find_fishing_tile() -> Vector2i:
	var from_x := _map.world_to_tile(_fisherman_hut.position).x
	var bounds := _map.get_tile_bounds()
	var row := Map.RIVER_ROW + 2
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for x in range(bounds.position.x, bounds.end.x):
		var tile := Vector2i(x, row)
		if not _map.visited_fish_tiles.has(tile):
			var dist := float(abs(x - from_x))
			if dist < best_dist:
				best_dist = dist
				best = tile
	return best
