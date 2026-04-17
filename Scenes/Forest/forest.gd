class_name Forest
extends Node2D

const TREE_COUNT := 30
const TREE_AREA_WIDTH := 20
const TREE_AREA_HEIGHT := 15

const TreeScene = preload("res://Scenes/Tree/Tree.tscn")

var trees: Dictionary = {}
var _map: Map = null

func setup(map: Map) -> void:
	_map = map
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
		add_child(tree)
		_map.occupied_tiles[tile_pos] = tree
		trees[tile_pos] = tree

func find_tree(from: Vector2, require_apples: bool) -> Dictionary:
	var best_tree: GameTree = null
	var best_dist := INF
	var best_tile := Vector2i.ZERO

	for tile: Vector2i in trees:
		var tree := trees[tile] as GameTree
		if require_apples:
			if tree.apple_targeted or not tree.has_apples:
				continue
		else:
			if tree.targeted:
				continue
		var dist: float = tree.position.distance_to(from)
		if dist < best_dist:
			best_dist = dist
			best_tree = tree
			best_tile = tile

	if best_tree == null:
		return {}
	return {tree = best_tree, tile = best_tile}

func remove_tree(tile: Vector2i) -> void:
	trees.erase(tile)
	_map.occupied_tiles.erase(tile)
