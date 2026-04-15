extends Node2D

const LEVEL_WIDTH := 60
const LEVEL_HEIGHT := 30

const TREE_COUNT := 30
const TREE_AREA_WIDTH := 20
const TREE_AREA_HEIGHT := 15

const TreeScene = preload("res://Scenes/Tree/Tree.tscn")

@onready var grass_layer: TileMapLayer = $Grass
@onready var camera: Camera2D = $Camera
@onready var building_manager = $BuildingManager

func _ready() -> void:
	for x in LEVEL_WIDTH:
		for y in LEVEL_HEIGHT:
			grass_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	var tile_size := grass_layer.tile_set.tile_size
	camera.setup(Vector2i(LEVEL_WIDTH * tile_size.x, LEVEL_HEIGHT * tile_size.y))

	_spawn_trees()

func _spawn_trees() -> void:
	var tile_size := grass_layer.tile_set.tile_size
	var start_x := randi_range(0, LEVEL_WIDTH - TREE_AREA_WIDTH)
	var start_y := randi_range(0, LEVEL_HEIGHT - TREE_AREA_HEIGHT)

	var positions: Array[Vector2i] = []
	for x in TREE_AREA_WIDTH:
		for y in TREE_AREA_HEIGHT:
			positions.append(Vector2i(start_x + x, start_y + y))
	positions.shuffle()

	for i in min(TREE_COUNT, positions.size()):
		var tile_pos := positions[i]
		var tree := TreeScene.instantiate()
		tree.position = grass_layer.map_to_local(tile_pos) + Vector2(0, tile_size.y / 2.0)
		add_child(tree)
		building_manager.occupied_tiles[tile_pos] = tree
