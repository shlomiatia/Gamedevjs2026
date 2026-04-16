extends Node2D

const TREE_COUNT := 30
const TREE_AREA_WIDTH := 20
const TREE_AREA_HEIGHT := 15

const TreeScene = preload("res://Scenes/Tree/Tree.tscn")

@onready var _map: Map = $Map
@onready var camera: Camera2D = $Camera
@onready var _building_manager: BuildingManager = $BuildingManager
@onready var _coordination_manager: Node = $CoordinationManager

func _ready() -> void:
	var tile_size := _map.get_tile_size()
	camera.setup(Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y))
	_building_manager.setup(_map, _coordination_manager)
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
		var tree := TreeScene.instantiate()
		tree.position = _map.tile_to_world(tile_pos) + Vector2(0, tile_size.y / 2.0)
		add_child(tree)
		_map.occupied_tiles[tile_pos] = tree
		_map.trees[tile_pos] = tree
