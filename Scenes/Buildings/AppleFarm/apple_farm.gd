class_name AppleFarm
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "AppleFarm"

const AppleFarmerScene = preload("res://Scenes/Workers/AppleFarmer/AppleFarmer.tscn")

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, forest: Forest) -> void:
	super.on_placed(spawn_parent, map, coordination_manager, forest)
	$OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.APPLE)
	_start_construction()

func complete_construction() -> void:
	super.complete_construction()
	var farmer := AppleFarmerScene.instantiate() as AppleFarmer
	farmer.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	farmer.setup(self, _map, _forest)
	_spawn_parent.add_child(farmer)
