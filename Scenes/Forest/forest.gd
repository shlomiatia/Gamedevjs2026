class_name Forest
extends Node2D

const TREE_COUNT := 30
const TREE_AREA_WIDTH := 20
const TREE_AREA_HEIGHT := 15

const TreeScene = preload("res://Scenes/Tree/Tree.tscn")

var trees: Dictionary = {}
var _map: Map = null
var _spawn_parent: Node2D = null

func setup(map: Map, spawn_parent: Node2D) -> void:
	_map = map
	_spawn_parent = spawn_parent
	_spawn_trees()

func _spawn_trees() -> void:
	var tile_size := _map.get_tile_size()
	var start_x := randi_range(0, Map.LEVEL_WIDTH - TREE_AREA_WIDTH)
	var start_y := randi_range(0, Map.LEVEL_HEIGHT - TREE_AREA_HEIGHT)

	var positions: Array[Vector2i] = []
	for x in TREE_AREA_WIDTH:
		for y in TREE_AREA_HEIGHT:
			positions.append(Vector2i(start_x + x, start_y + y))
	positions.shuffle()

	for i in min(TREE_COUNT, positions.size()):
		var tile_pos := positions[i]
		if _map.occupied_tiles.has(tile_pos):
			continue
		var tree := TreeScene.instantiate() as GameTree
		tree.position = _map.tile_to_world(tile_pos) + Vector2(0, tile_size.y / 2.0)
		_spawn_parent.add_child(tree)
		tree.setup(_map, tile_pos)
		trees[tile_pos] = tree

func find_tree(from: Vector2, require_apples: bool) -> Dictionary:
	var start := _map.world_to_tile(from)
	var bounds := _map.get_tile_bounds()
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}
	while not queue.is_empty():
		var tile: Vector2i = queue.pop_front()
		if trees.has(tile):
			var tree := trees[tile] as GameTree
			var usable := not tree.targeted and (not require_apples or tree.has_apples)
			if usable:
				return {tree = tree, tile = tile}
		for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor := tile + offset
			if not visited.has(neighbor) and bounds.has_point(neighbor):
				visited[neighbor] = true
				queue.append(neighbor)
	return {}

func remove_tree(tile: Vector2i) -> void:
	trees[tile].remove_from_map()
	trees.erase(tile)
