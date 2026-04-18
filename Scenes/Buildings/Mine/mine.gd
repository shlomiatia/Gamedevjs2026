class_name Mine
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "Mine"
const CONSTRUCTION_RESOURCE_TYPE := CoordinationManager.ResourceType.PLANK

const MinerScene = preload("res://Scenes/Workers/Miner/Miner.tscn")

@export var output_resource_type: int = CoordinationManager.ResourceType.CLAY
@export var output_scene: PackedScene = null

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null

func get_pile_for_type(type: int) -> ResourcePile:
	return $Building.get_output_pile() if type == output_resource_type else null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return top_left.y + SIZE_Y == map.LEVEL_HEIGHT - 6 and $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	$Building.get_output_pile().setup(coordination_manager, output_resource_type)
	$Building.start_construction()
	coordination_manager.queue_construction(self)

func complete_construction() -> void:
	$Building.complete_construction()
	var tile_size := _map.get_tile_size()
	var pile_offset := Vector2((SIZE_X / 2.0 + 0.5) * tile_size.x, -1.5 * tile_size.y)
	var miner := MinerScene.instantiate() as Miner
	miner.position = position + pile_offset
	miner.setup(self, $Building.get_output_pile(), output_scene, _map, _coordination_manager)
	_spawn_parent.add_child(miner)
