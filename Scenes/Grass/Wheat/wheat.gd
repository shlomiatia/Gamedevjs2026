class_name WheatLayer
extends Node2D

var _grass_layer: TileMapLayer = null
var _occupied_tiles: Dictionary = {}

var _wheat_texture: AtlasTexture = null
var _wheat_sprites: Dictionary = {}
var _wheat_ready: Dictionary = {}
var _wheat_harvesting: Dictionary = {}

func setup(grass_layer: TileMapLayer, occupied_tiles: Dictionary) -> void:
	_grass_layer = grass_layer
	_occupied_tiles = occupied_tiles
	_wheat_texture = AtlasTexture.new()
	_wheat_texture.atlas = load("res://Textures/wheat tileset.png") as Texture2D
	_wheat_texture.region = Rect2(0, 96, 32, 32)

func plant_wheat(tile: Vector2i, grow_duration: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _wheat_texture
	sprite.position = _grass_layer.map_to_local(tile)
	sprite.modulate.a = 0.0
	add_child(sprite)
	_wheat_sprites[tile] = sprite
	_wheat_ready[tile] = false
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, grow_duration)
	tween.tween_callback(func(): _wheat_ready[tile] = true)

func is_wheat_ready(tile: Vector2i) -> bool:
	return _wheat_ready.get(tile, false)

func find_ready_wheat_tile(near_pos: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for tile: Vector2i in _wheat_ready:
		if _wheat_ready[tile] and not _wheat_harvesting.has(tile):
			var world_pos := _grass_layer.map_to_local(tile)
			var dist := near_pos.distance_to(world_pos)
			if dist < best_dist:
				best_dist = dist
				best = tile
	return best

func find_wheat_planting_tile(near_pos: Vector2, extra_occupied: Dictionary = {}) -> Vector2i:
	var start := _grass_layer.local_to_map(near_pos)
	var bounds := _grass_layer.get_used_rect()
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		if not _occupied_tiles.has(tile) and not extra_occupied.has(tile) and not _wheat_sprites.has(tile) and _grass_layer.get_cell_atlas_coords(tile) == Vector2i(0, 0):
			return tile
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor := tile + offset
			if not visited.has(neighbor) and bounds.has_point(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return Vector2i(-1, -1)

func get_wheat_tile_count() -> int:
	return _wheat_sprites.size()

func start_wheat_harvest_tween(tile: Vector2i, duration: float) -> void:
	_wheat_harvesting[tile] = true
	var sprite := _wheat_sprites.get(tile) as Sprite2D
	if sprite == null:
		return
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, duration)

func finish_wheat_harvest(tile: Vector2i) -> void:
	var sprite: Sprite2D = _wheat_sprites.get(tile)
	if sprite != null:
		sprite.queue_free()
	_wheat_sprites.erase(tile)
	_wheat_ready.erase(tile)
	_wheat_harvesting.erase(tile)
	_occupied_tiles.erase(tile)
