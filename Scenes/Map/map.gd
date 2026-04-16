class_name Map
extends Node2D

const LEVEL_WIDTH := 60
const LEVEL_HEIGHT := 30
const RIVER_ROW := 0
const RIVER_FRAMES := 32
const RIVER_COLS := 6
const RIVER_FPS := 10.0

var occupied_tiles: Dictionary = {}

@onready var grass: TileMapLayer = $Grass
@onready var river: TileMapLayer = $River

var _river_frame := 0
var _river_timer := 0.0

func _ready() -> void:
	for x in LEVEL_WIDTH:
		for y in LEVEL_HEIGHT:
			grass.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	for x in LEVEL_WIDTH:
		river.set_cell(Vector2i(x, RIVER_ROW), 0, Vector2i(0, 0))
		grass.set_cell(Vector2i(x, RIVER_ROW), 0, Vector2i(0, 1))
		occupied_tiles[Vector2i(x, RIVER_ROW)] = true

func _process(delta: float) -> void:
	_river_timer += delta
	if _river_timer >= 1.0 / RIVER_FPS:
		_river_timer -= 1.0 / RIVER_FPS
		_river_frame = (_river_frame + 1) % RIVER_FRAMES
		var col := _river_frame % RIVER_COLS
		var row := _river_frame / RIVER_COLS
		for x in LEVEL_WIDTH:
			river.set_cell(Vector2i(x, RIVER_ROW), 0, Vector2i(col, row))

func get_tile_size() -> Vector2i:
	return grass.tile_set.tile_size

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return grass.local_to_map(world_pos)

func tile_to_world(tile: Vector2i) -> Vector2:
	return grass.map_to_local(tile)

func get_mouse_tile() -> Vector2i:
	return grass.local_to_map(grass.get_local_mouse_position())

func find_path(from_world: Vector2, to_world: Vector2) -> Array[Vector2]:
	var from_tile := world_to_tile(from_world)
	var to_tile := world_to_tile(to_world)
	var tile_path := _astar(from_tile, to_tile)
	var result: Array[Vector2] = []
	for t in tile_path:
		result.append(tile_to_world(t))
	return result

func _astar(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if from == to:
		return [to]

	var bounds := grass.get_used_rect()
	var open_set: Array[Vector2i] = [from]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from: 0.0}
	var f_score: Dictionary = {from: _heuristic(from, to)}
	var iterations := 0

	while not open_set.is_empty() and iterations < 10000:
		iterations += 1
		var current_idx := 0
		for i in open_set.size():
			if f_score.get(open_set[i], INF) < f_score.get(open_set[current_idx], INF):
				current_idx = i
		var current: Vector2i = open_set[current_idx]
		if current == to:
			return _reconstruct_path(came_from, current)
		open_set.remove_at(current_idx)
		for neighbor in _get_neighbors(current, bounds):
			if occupied_tiles.has(neighbor) and neighbor != to:
				continue
			var tentative_g: float = g_score.get(current, INF) + 1.0
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, to)
				if not open_set.has(neighbor):
					open_set.append(neighbor)

	return [to]

func _heuristic(a: Vector2i, b: Vector2i) -> float:
	return float(abs(a.x - b.x) + abs(a.y - b.y))

func _get_neighbors(tile: Vector2i, bounds: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = tile + offset
		if bounds.has_point(n):
			result.append(n)
	return result

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path
