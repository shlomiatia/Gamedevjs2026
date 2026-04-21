class_name Bakery
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "Bakery"
const CONSTRUCTION_RESOURCE_TYPE = CoordinationManager.ResourceType.BRICK

const KilnWorkerScene = preload("res://Scenes/Workers/KilnWorker/KilnWorker.tscn")
const BreadScene = preload("res://Scenes/Resources/Bread/Bread.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _spawn_pos: Vector2
var _output_pile: ResourcePile
var _smoking := false

func get_pile_for_type(type: int) -> ResourcePile:
	return _output_pile if type == CoordinationManager.ResourceType.BREAD else null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return $Building.validate_placement(top_left, map)

func set_smoking(val: bool) -> void:
	_smoking = val
	$Smoke.emitting = val

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	_output_pile = $Building.get_output_pile()
	_output_pile.setup(coordination_manager, CoordinationManager.ResourceType.BREAD)
	var tiles := map.find_building_spawn_tiles(position, Vector2i(SIZE_X, SIZE_Y))
	_spawn_pos = map.tile_to_world(tiles[0])
	_output_pile.reparent(spawn_parent)
	_output_pile.global_position = map.tile_to_world(tiles[1])
	_output_pile.visible = false
	$Building.start_construction()
	coordination_manager.queue_construction(self)

func complete_construction() -> void:
	$Building.complete_construction()
	_output_pile.visible = true
	var worker := KilnWorkerScene.instantiate() as KilnWorker
	worker.position = _spawn_pos
	worker.setup(self, _map, _coordination_manager, BreadScene,
		CoordinationManager.ResourceType.FLOUR, CoordinationManager.ResourceType.LOG, _output_pile, "Baker")
	_spawn_parent.add_child(worker)
