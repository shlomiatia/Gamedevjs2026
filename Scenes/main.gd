extends Node2D

@onready var _map: Map = $Map
@onready var camera: Camera2D = $Camera
@onready var _building_manager: BuildingManager = $BuildingManager
@onready var _coordination_manager: CoordinationManager = $CoordinationManager
@onready var _forest: Forest = $Forest

@onready var _game_over_ui: CanvasLayer = $GameOverUI
@onready var _game_won_ui: CanvasLayer = $GameWonUI

var _hud: HUD
var _tutorial: Tutorial

func _on_game_over() -> void:
	_game_over_ui.visible = true

func _on_game_won() -> void:
	_game_won_ui.visible = true

func _ready() -> void:
	var tile_size := _map.get_tile_size()
	camera.setup(Vector2i(Map.LEVEL_WIDTH * tile_size.x, Map.LEVEL_HEIGHT * tile_size.y))
	_forest.setup(_map, self)
	_building_manager.setup(_map, _coordination_manager, _forest)
	_coordination_manager.game_over.connect(_on_game_over)
	_coordination_manager.game_won.connect(_on_game_won)

	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	_hud = HUD.new()
	_hud.setup(_coordination_manager)
	hud_layer.add_child(_hud)

	_tutorial = Tutorial.new()
	add_child(_tutorial)
	_tutorial.setup(_coordination_manager, _building_manager, _hud, camera)

	camera.panned.connect(func(): _tutorial.on_event("panned"))
	_building_manager.building_button_pressed.connect(func(key: String):
		if key == "BuilderHut":
			_tutorial.on_event("builder_button_clicked")
		elif key == "WoodcutterHut" or key == "Sawmill":
			_tutorial.on_event("woodcutter_or_sawmill_clicked")
	)
	_building_manager.building_placed.connect(func(key: String):
		_tutorial.on_event("building_placed:" + key)
	)
	_coordination_manager.construction_queued.connect(func():
		_tutorial.on_event("construction_queued")
	)
	_coordination_manager.worker_registered.connect(func(count: int):
		if count >= 3:
			_tutorial.on_event("worker_count:3")
	)
	_coordination_manager.worker_became_hungry.connect(func():
		_tutorial.on_event("hungry_worker")
	)

	_tutorial.start()
