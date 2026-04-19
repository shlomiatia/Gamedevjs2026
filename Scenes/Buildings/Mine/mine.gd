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
var _spawn_pos: Vector2

func get_pile_for_type(type: int) -> ResourcePile:
	return $Building.get_output_pile() if type == output_resource_type else null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return top_left.y + SIZE_Y == map.LEVEL_HEIGHT - 6 and $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	$Building.get_output_pile().setup(coordination_manager, output_resource_type)
	var tiles := map.find_building_spawn_tiles(position, Vector2i(SIZE_X, SIZE_Y))
	if tiles.size() >= 1:
		_spawn_pos = map.tile_to_world(tiles[0])
	if tiles.size() >= 2:
		$Building.get_output_pile().position = map.tile_to_world(tiles[1]) - position
	$Building.start_construction()
	coordination_manager.queue_construction(self)

func complete_construction() -> void:
	$Building.complete_construction()
	var miner := MinerScene.instantiate() as Miner
	miner.position = _spawn_pos
	miner.setup(self, $Building.get_output_pile(), output_scene, _map, _coordination_manager)
	_spawn_parent.add_child(miner)
