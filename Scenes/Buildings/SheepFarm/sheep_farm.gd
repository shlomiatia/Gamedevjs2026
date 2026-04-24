class_name SheepFarm
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "Sheep Farm"

const SheepFarmerScene = preload("res://Scenes/Workers/SheepFarmer/SheepFarmer.tscn")
const SheepScene = preload("res://Scenes/Sheep/Sheep.tscn")
const ResourcePileScene = preload("res://Scenes/Resources/ResourcePile/ResourcePile.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _spawn_pos: Vector2
var _wool_pile: ResourcePile
var _milk_pile: ResourcePile

func get_pile_for_type(type: int) -> ResourcePile:
	match type:
		CoordinationManager.ResourceType.WOOL: return _wool_pile
		CoordinationManager.ResourceType.MILK: return _milk_pile
	return null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	_wool_pile = $Building.get_output_pile()
	_wool_pile.setup(coordination_manager, CoordinationManager.ResourceType.WOOL)
	var tiles := map.find_building_spawn_tiles(position, Vector2i(SIZE_X, SIZE_Y), 3)
	_spawn_pos = map.tile_to_world(tiles[0])
	_wool_pile.reparent(spawn_parent)
	_wool_pile.global_position = map.tile_to_world(tiles[1])
	_wool_pile.visible = false
	_milk_pile = ResourcePileScene.instantiate() as ResourcePile
	_milk_pile.setup(coordination_manager, CoordinationManager.ResourceType.MILK)
	spawn_parent.add_child(_milk_pile)
	_milk_pile.global_position = map.tile_to_world(tiles[2])
	_milk_pile.visible = false
	$Building.start_construction()
	coordination_manager.queue_construction(self )

func complete_construction() -> void:
	$Building.complete_construction()
	_wool_pile.visible = true
	_milk_pile.visible = true

	var sheep := SheepScene.instantiate() as Sheep
	sheep.position = _spawn_pos
	_spawn_parent.add_child(sheep)
	sheep.shear()

	var farmer := SheepFarmerScene.instantiate() as SheepFarmer
	farmer.position = _spawn_pos
	farmer.setup(self , _map, sheep, _spawn_parent, _coordination_manager, _wool_pile, _milk_pile)
	_spawn_parent.add_child(farmer)
