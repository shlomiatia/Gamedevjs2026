class_name Map
extends Node2D

const LEVEL_WIDTH := 70
const LEVEL_HEIGHT := 40
const RIVER_ROW := 4

enum OccupiedType {BLOCK_BUILDING = 1, BLOCK_WORKERS = 2}

var occupied_tiles: Dictionary = {}

@onready var _grass: Grass = $Grass
@onready var _river: River = $River
@onready var _mountain: Mountain = $Mountain
@onready var _nav_region: NavigationRegion2D = $NavRegion

var wheat: WheatLayer:
	get: return _grass.wheat

func _ready() -> void:
	_grass.setup(LEVEL_WIDTH, LEVEL_HEIGHT, RIVER_ROW, 2, occupied_tiles)
	_river.setup(LEVEL_WIDTH, RIVER_ROW, 2)
	_mountain.setup(LEVEL_WIDTH, LEVEL_HEIGHT, get_tile_size())
	set_occupied_tiles_rect(Vector2i(0, 0), Vector2i(LEVEL_WIDTH, RIVER_ROW + 2), OccupiedType.BLOCK_WORKERS)
	set_occupied_tiles_rect(Vector2i(0, LEVEL_HEIGHT - 6), Vector2i(LEVEL_WIDTH, 6), OccupiedType.BLOCK_WORKERS)
	set_occupied_tiles_rect(Vector2i(-1, 0), Vector2i(1, LEVEL_HEIGHT), OccupiedType.BLOCK_WORKERS)
	set_occupied_tiles_rect(Vector2i(LEVEL_WIDTH, 0), Vector2i(1, LEVEL_HEIGHT), OccupiedType.BLOCK_WORKERS)
	_setup_navigation()

var _nav_outer: PackedVector2Array
var _nav_holes: Array = []

func _setup_navigation() -> void:
	var ts := get_tile_size()
	var tl := tile_to_world(Vector2i(0, RIVER_ROW + 2)) - Vector2(ts.x * 0.5, ts.y * 0.5)
	var br := tile_to_world(Vector2i(LEVEL_WIDTH - 1, LEVEL_HEIGHT - 7)) + Vector2(ts.x * 0.5, ts.y * 0.5)
	_nav_outer = PackedVector2Array([tl, Vector2(br.x, tl.y), br, Vector2(tl.x, br.y)])
	_bake_nav_mesh()

func add_nav_hole(hole: PackedVector2Array) -> void:
	var nav_min_x: float = _nav_outer[0].x
	var nav_max_x: float = _nav_outer[0].x
	var nav_min_y: float = _nav_outer[0].y
	var nav_max_y: float = _nav_outer[0].y
	for p: Vector2 in _nav_outer:
		if p.x < nav_min_x: nav_min_x = p.x
		if p.x > nav_max_x: nav_max_x = p.x
		if p.y < nav_min_y: nav_min_y = p.y
		if p.y > nav_max_y: nav_max_y = p.y
	# Inset by 1px so holes never touch the outer polygon edge (breaks make_polygons_from_outlines)
	var bx0: float = nav_min_x + 1.0
	var bx1: float = nav_max_x - 1.0
	var by0: float = nav_min_y + 1.0
	var by1: float = nav_max_y - 1.0
	# Find hole's axis-aligned bounding box
	var hx0: float = hole[0].x
	var hx1: float = hole[0].x
	var hy0: float = hole[0].y
	var hy1: float = hole[0].y
	for p: Vector2 in hole:
		if p.x < hx0: hx0 = p.x
		if p.x > hx1: hx1 = p.x
		if p.y < hy0: hy0 = p.y
		if p.y > hy1: hy1 = p.y
	# Clip hole rect to inset nav boundary
	var cx0: float = hx0 if hx0 > bx0 else bx0
	var cx1: float = hx1 if hx1 < bx1 else bx1
	var cy0: float = hy0 if hy0 > by0 else by0
	var cy1: float = hy1 if hy1 < by1 else by1
	if cx0 >= cx1 or cy0 >= cy1:
		return
	_nav_holes.append(PackedVector2Array([
		Vector2(cx0, cy0), Vector2(cx0, cy1),
		Vector2(cx1, cy1), Vector2(cx1, cy0)
	]))
	_bake_nav_mesh()

func _bake_nav_mesh() -> void:
	var nav_poly := NavigationPolygon.new()
	nav_poly.add_outline(_nav_outer)
	for hole in _nav_holes:
		nav_poly.add_outline(hole)
	nav_poly.make_polygons_from_outlines()
	_nav_region.navigation_polygon = nav_poly

func set_occupied_tiles_rect(top_left: Vector2i, size: Vector2i, value) -> void:
	for dx in size.x:
		for dy in size.y:
			occupied_tiles[Vector2i(top_left.x + dx, top_left.y + dy)] = value

func set_occupied_ring(top_left: Vector2i, size: Vector2i, value: int) -> void:
	for x in range(top_left.x - 1, top_left.x + size.x + 1):
		for y in range(top_left.y - 1, top_left.y + size.y + 1):
			var tile := Vector2i(x, y)
			if x >= top_left.x and x < top_left.x + size.x and y >= top_left.y and y < top_left.y + size.y:
				continue
			if occupied_tiles.get(tile, 0) < value:
				occupied_tiles[tile] = value

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

func find_grass_tile(near_pos: Vector2, extra_occupied: Dictionary = {}) -> Vector2i:
	return _grass.find_grass_tile(near_pos, extra_occupied)

func find_sheep_grass_tile(near_pos: Vector2, extra_occupied: Dictionary = {}) -> Vector2i:
	return _grass.find_sheep_grass_tile(near_pos, extra_occupied)

func eat_grass(tile: Vector2i) -> void:
	_grass.eat_grass(tile)

func start_grass_fade(tiles: Array[Vector2i], duration: float) -> void:
	_grass.start_grass_fade(tiles, duration)

func find_building_spawn_tiles(building_pos: Vector2, size: Vector2i, count: int = 2) -> Array[Vector2i]:
	var tile_size := get_tile_size()
	var tl_world := Vector2(
		building_pos.x - (size.x - 1) * tile_size.x / 2.0,
		building_pos.y - (size.y - 0.5) * tile_size.y
	)
	var top_left := world_to_tile(tl_world)
	var run: Array[Vector2i] = []
	for tile in _ring_clockwise(top_left, size):
		if occupied_tiles.get(tile, 0) != OccupiedType.BLOCK_WORKERS:
			run.append(tile)
			if run.size() == count:
				return run
		else:
			run.clear()
	assert(false, "find_building_spawn_tiles: could not find %d consecutive free tiles" % count)
	return []

func _ring_clockwise(top_left: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var right := top_left.x + size.x
	var bottom := top_left.y + size.y
	var left := top_left.x - 1
	var top := top_left.y - 1
	var center_x := top_left.x + size.x / 2
	for x in range(center_x, right + 1):
		result.append(Vector2i(x, bottom))
	for y in range(bottom - 1, top - 1, -1):
		result.append(Vector2i(right, y))
	for x in range(right - 1, left - 1, -1):
		result.append(Vector2i(x, top))
	for y in range(top + 1, bottom + 1):
		result.append(Vector2i(left, y))
	for x in range(left + 1, center_x):
		result.append(Vector2i(x, bottom))
	return result
