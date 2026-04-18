class_name Sawmill
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "Sawmill"

const MillerScene = preload("res://Scenes/Workers/Miller/Miller.tscn")
const PlankScene = preload("res://Scenes/Resources/Plank/Plank.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null

func get_pile_for_type(type: int) -> ResourcePile:
	return $Building.get_output_pile() if type == CoordinationManager.ResourceType.PLANK else null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	$Building.get_output_pile().setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	$Building.start_construction()
	coordination_manager.queue_construction(self)

func complete_construction() -> void:
	$Building.complete_construction()
	var miller := MillerScene.instantiate() as Miller
	miller.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	miller.setup(self, _map, _coordination_manager, CoordinationManager.ResourceType.LOG, PlankScene)
	_spawn_parent.add_child(miller)

