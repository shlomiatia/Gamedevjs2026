class_name Map
extends Node2D

const LEVEL_WIDTH := 60
const LEVEL_HEIGHT := 30
const RIVER_ROW := 3
const RIVER_FRAMES := 32
const RIVER_COLS := 6
const RIVER_FPS := 10.0

var occupied_tiles: Dictionary = {}
var eaten_tiles: Dictionary = {}

@onready var grass: TileMapLayer = $Grass
@onready var dirt: TileMapLayer = $Dirt
@onready var river_and_dirt: TileMapLayer = $RiverAndDirt

var _river_frame := 0
var _river_timer := 0.0

func _ready() -> void:
    for x in LEVEL_WIDTH:
        for y in LEVEL_HEIGHT:
            grass.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
            if y != RIVER_ROW:
                dirt.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))

    for x in LEVEL_WIDTH:
        for y in RIVER_ROW:
            occupied_tiles[Vector2i(x, y)] = true
        river_and_dirt.set_cell(Vector2i(x, RIVER_ROW), 0, Vector2i(0, 0))
        grass.set_cell(Vector2i(x, RIVER_ROW), 0, Vector2i(0, 1))
        occupied_tiles[Vector2i(x, RIVER_ROW)] = true

func _process(delta: float) -> void:
    _river_timer += delta
    if _river_timer >= 1.0 / RIVER_FPS:
        _river_timer -= 1.0 / RIVER_FPS
        _river_frame = (_river_frame + 1) % RIVER_FRAMES
        var col := _river_frame % RIVER_COLS
        var row: int = _river_frame / RIVER_COLS
        for x in LEVEL_WIDTH:
            river_and_dirt.set_cell(Vector2i(x, RIVER_ROW), 0, Vector2i(col, row))

func get_tile_size() -> Vector2i:
    return grass.tile_set.tile_size

func world_to_tile(world_pos: Vector2) -> Vector2i:
    return grass.local_to_map(world_pos)

func tile_to_world(tile: Vector2i) -> Vector2:
    return grass.map_to_local(tile)

func get_mouse_tile() -> Vector2i:
    return grass.local_to_map(grass.get_local_mouse_position())

func find_grass_tile(near_pos: Vector2) -> Vector2i:
    var best := Vector2i(-1, -1)
    var best_dist := INF
    for tile in grass.get_used_cells():
        if occupied_tiles.has(tile):
            continue
        if grass.get_cell_atlas_coords(tile) != Vector2i(0, 0):
            continue
        var dist := tile_to_world(tile).distance_to(near_pos)
        if dist < best_dist:
            best_dist = dist
            best = tile
    return best

func eat_grass(tile: Vector2i) -> void:
    eaten_tiles[tile] = true
    occupied_tiles[tile] = true
    _update_dirt_tile(tile)
    for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
        var neighbor: Vector2i = tile + offset
        if eaten_tiles.has(neighbor):
            _update_dirt_tile(neighbor)

func _update_dirt_tile(tile: Vector2i) -> void:
    var mask := 0
    if eaten_tiles.has(tile + Vector2i(0, -1)): mask |= 1  # up
    if eaten_tiles.has(tile + Vector2i(1,  0)): mask |= 2  # right
    if eaten_tiles.has(tile + Vector2i(0,  1)): mask |= 4  # down
    if eaten_tiles.has(tile + Vector2i(-1, 0)): mask |= 8  # left
    if mask == 15:
        grass.erase_cell(tile)
    else:
        grass.set_cell(tile, 0, _dirt_tile_for_mask(mask))

func _dirt_tile_for_mask(mask: int) -> Vector2i:
    match mask:
        0:  return Vector2i(5, 0)  # isolated → grass frame (transparent center)
        1:  return Vector2i(2, 2)  # up only
        2:  return Vector2i(3, 2)  # right only
        4:  return Vector2i(2, 3)  # down only
        8:  return Vector2i(3, 3)  # left only
        3:  return Vector2i(0, 5)  # up+right   → grass bottom+left
        5:  return Vector2i(1, 1)  # up+down (straight)
        6:  return Vector2i(0, 4)  # right+down → grass top+left
        9:  return Vector2i(1, 5)  # up+left    → grass bottom+right
        10: return Vector2i(0, 1)  # right+left (straight)
        12: return Vector2i(1, 4)  # down+left  → grass top+right
        7:  return Vector2i(6, 2)  # up+right+down, missing left  → left edge grass
        11: return Vector2i(5, 1)  # up+right+left, missing down  → bottom edge grass
        13: return Vector2i(4, 2)  # up+down+left,  missing right → right edge grass
        14: return Vector2i(5, 3)  # right+down+left, missing up  → top edge grass
        _:  return Vector2i(1, 0)  # fallback: full dirt

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

    return [to]

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
