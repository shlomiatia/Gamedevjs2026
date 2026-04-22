class_name Grass
extends Node2D

@onready var wheat: WheatLayer = $Wheat
@onready var _grass_layer: TileMapLayer = $GrassLayer
@onready var _dirt_layer: TileMapLayer = $DirtLayer
@onready var _fade_layer: TileMapLayer = $FadeLayer

var _occupied_tiles: Dictionary = {}
var _eaten_tiles: Dictionary = {}
var _fade_tiles: Array[Vector2i] = []
var _fade_tween: Tween = null

func setup(level_width: int, level_height: int, river_row: int, river_rows: int = 1, occupied_tiles: Dictionary = {}) -> void:
    _occupied_tiles = occupied_tiles
    wheat.setup(_grass_layer, occupied_tiles)
    for x in level_width:
        for y in level_height:
            _grass_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
            if y < river_row or y >= river_row + river_rows:
                _dirt_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
    for x in level_width:
        _grass_layer.set_cell(Vector2i(x, river_row), 0, Vector2i(5, 3))
        for r in range(1, river_rows):
            _grass_layer.set_cell(Vector2i(x, river_row + r), 0, Vector2i(5, 1))

func get_tile_size() -> Vector2i:
    return _grass_layer.tile_set.tile_size

func local_to_map(pos: Vector2) -> Vector2i:
    return _grass_layer.local_to_map(pos)

func map_to_local(tile: Vector2i) -> Vector2:
    return _grass_layer.map_to_local(tile)

func get_used_rect() -> Rect2i:
    return _grass_layer.get_used_rect()

func get_mouse_tile() -> Vector2i:
    return _grass_layer.local_to_map(_grass_layer.get_local_mouse_position())

func start_grass_fade(tiles: Array[Vector2i], duration: float) -> void:
    if _fade_tween:
        _fade_tween.kill()
    _clear_fade_layer()
    var snapshot: Dictionary = {}
    for tile in tiles:
        snapshot[tile] = true
        for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
            var n := tile + offset
            if _eaten_tiles.has(n):
                snapshot[n] = true
    for tile: Vector2i in snapshot:
        var coords := _grass_layer.get_cell_atlas_coords(tile)
        if coords != Vector2i(-1, -1):
            _fade_layer.set_cell(tile, 0, coords)
            _fade_tiles.append(tile)
    for tile in tiles:
        eat_grass(tile)
    _fade_layer.modulate.a = 1.0
    _fade_tween = create_tween()
    _fade_tween.tween_property(_fade_layer, "modulate:a", 0.0, duration)
    _fade_tween.tween_callback(_clear_fade_layer)

func _clear_fade_layer() -> void:
    for tile in _fade_tiles:
        _fade_layer.erase_cell(tile)
    _fade_tiles.clear()
    _fade_layer.modulate.a = 1.0

func eat_grass(tile: Vector2i) -> void:
    _eaten_tiles[tile] = true
    _update_dirt_tile(tile)
    for offset: Vector2i in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
        var neighbor: Vector2i = tile + offset
        if _eaten_tiles.has(neighbor):
            _update_dirt_tile(neighbor)

func find_sheep_grass_tile(near_pos: Vector2, extra_occupied: Dictionary = {}) -> Vector2i:
    var start := _grass_layer.local_to_map(near_pos)
    var bounds := _grass_layer.get_used_rect()
    var queue: Array[Vector2i] = [start]
    var visited: Dictionary = {start: true}
    while not queue.is_empty():
        var tile: Vector2i = queue.pop_front()
        if _occupied_tiles.get(tile, 0) != Map.OccupiedType.BLOCK_WORKERS and not extra_occupied.has(tile) and _grass_layer.get_cell_atlas_coords(tile) == Vector2i(0, 0):
            return tile
        for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
            var neighbor := tile + offset
            if not visited.has(neighbor) and bounds.has_point(neighbor):
                visited[neighbor] = true
                queue.append(neighbor)
    return Vector2i(-1, -1)

func _update_dirt_tile(tile: Vector2i) -> void:
    var mask := 0
    if _eaten_tiles.has(tile + Vector2i(0, -1)): mask |= 1
    if _eaten_tiles.has(tile + Vector2i(1, 0)): mask |= 2
    if _eaten_tiles.has(tile + Vector2i(0, 1)): mask |= 4
    if _eaten_tiles.has(tile + Vector2i(-1, 0)): mask |= 8
    if mask == 15:
        _grass_layer.erase_cell(tile)
    else:
        _grass_layer.set_cell(tile, 0, _dirt_tile_for_mask(mask))

func _dirt_tile_for_mask(mask: int) -> Vector2i:
    match mask:
        0: return Vector2i(5, 0)
        1: return Vector2i(2, 2)
        2: return Vector2i(3, 2)
        4: return Vector2i(2, 3)
        8: return Vector2i(3, 3)
        3: return Vector2i(0, 5)
        5: return Vector2i(1, 1)
        6: return Vector2i(0, 4)
        9: return Vector2i(1, 5)
        10: return Vector2i(0, 1)
        12: return Vector2i(1, 4)
        7: return Vector2i(6, 2)
        11: return Vector2i(5, 1)
        13: return Vector2i(4, 2)
        14: return Vector2i(5, 3)
        _: return Vector2i(1, 0)
