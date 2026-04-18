class_name Map
extends Node2D

const LEVEL_WIDTH := 60
const LEVEL_HEIGHT := 30
const RIVER_ROW := 3

var occupied_tiles: Dictionary = {}
var eaten_tiles: Dictionary = {}

@onready var _grass: Grass = $Grass
@onready var _river: River = $River

func _ready() -> void:
	_grass.setup(LEVEL_WIDTH, LEVEL_HEIGHT, RIVER_ROW)
	_river.setup(LEVEL_WIDTH, RIVER_ROW)
	set_occupied_tiles_rect(Vector2i(0, 0), Vector2i(LEVEL_WIDTH, RIVER_ROW + 1), true)

func set_occupied_tiles_rect(top_left: Vector2i, size: Vector2i, value) -> void:
	for dx in size.x:
		for dy in size.y:
			occupied_tiles[Vector2i(top_left.x + dx, top_left.y + dy)] = value

func get_tile_size() -> Vector2i:
	return _grass.get_tile_size()

func world_to_tile(world_pos: Vector2) -> Vector2i:
	return _grass.local_to_map(world_pos)

func tile_to_world(tile: Vector2i) -> Vector2:
	return _grass.map_to_local(tile)

func get_tile_bounds() -> Rect2i:
	return _grass.get_used_rect()

func get_mouse_tile() -> Vector2i:
	return _grass.get_mouse_tile()

func find_grass_tile(near_pos: Vector2) -> Vector2i:
	return _grass.find_grass_tile(near_pos, occupied_tiles)

func eat_grass(tile: Vector2i) -> void:
	_grass.eat_grass(tile)

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

	var bounds := _grass.get_used_rect()
	var open_heap: Array = [[_heuristic(from, to), from]]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from: 0.0}
	var closed: Dictionary = {}

	while not open_heap.is_empty():
		var entry: Array = _heap_pop(open_heap)
		var current: Vector2i = entry[1]
		if closed.has(current):
			continue
		closed[current] = true
		if current == to:
			return _reconstruct_path(came_from, current)
		for neighbor in _get_neighbors(current, bounds):
			if occupied_tiles.has(neighbor) and neighbor != to:
				continue
			if closed.has(neighbor):
				continue
			var tentative_g: float = g_score.get(current, INF) + 1.0
			if tentative_g < g_score.get(neighbor, INF):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				_heap_push(open_heap, [tentative_g + _heuristic(neighbor, to), neighbor])

	return []

func _heap_push(heap: Array, entry: Array) -> void:
	heap.append(entry)
	var i := heap.size() - 1
	while i > 0:
		var parent := (i - 1) / 2
		if heap[parent][0] <= heap[i][0]:
			break
		var tmp = heap[parent]
		heap[parent] = heap[i]
		heap[i] = tmp
		i = parent

func _heap_pop(heap: Array) -> Array:
	var top = heap[0]
	var last = heap.pop_back()
	if not heap.is_empty():
		heap[0] = last
		var i := 0
		while true:
			var left := 2 * i + 1
			var right := 2 * i + 2
			var smallest := i
			if left < heap.size() and heap[left][0] < heap[smallest][0]:
				smallest = left
			if right < heap.size() and heap[right][0] < heap[smallest][0]:
				smallest = right
			if smallest == i:
				break
			var tmp = heap[smallest]
			heap[smallest] = heap[i]
			heap[i] = tmp
			i = smallest
	return top

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
