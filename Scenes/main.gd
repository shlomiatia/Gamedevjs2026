extends Node2D

@onready var _map: Map = $Map
@onready var camera: Camera2D = $Camera
@onready var _building_manager: BuildingManager = $BuildingManager
@onready var _coordination_manager: Node = $CoordinationManager
@onready var _forest: Forest = $Forest

@onready var _game_over_ui: CanvasLayer = $GameOverUI

func _on_game_over() -> void:
	_game_over_ui.visible = true

func _ready() -> void:
	var tile_size := _map.get_tile_size()
	camera.setup(Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y))
	_forest.setup(_map, self)
	_building_manager.setup(_map, _coordination_manager, _forest)
	(_coordination_manager as CoordinationManager).game_over.connect(_on_game_over)
