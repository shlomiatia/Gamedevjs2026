extends Node2D

@onready var _map: Map = $Map
@onready var camera: Camera2D = $Camera
@onready var _building_manager: BuildingManager = $BuildingManager
@onready var _coordination_manager: Node = $CoordinationManager
@onready var _forest: Forest = $Forest

func _ready() -> void:
	var tile_size := _map.get_tile_size()
	camera.setup(Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y))
	_forest.setup(_map)
	_building_manager.setup(_map, _coordination_manager, _forest)
