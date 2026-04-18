class_name BuilderHut
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "BuilderHut"

const BuilderScene = preload("res://Scenes/Workers/Builder/Builder.tscn")
const PlankScene = preload("res://Scenes/Resources/Plank/Plank.tscn")
const BrickScene = preload("res://Scenes/Resources/Brick/Brick.tscn")

var _map: Map = null

func get_pile_for_type(type: int) -> ResourcePile:
	if type == CoordinationManager.ResourceType.PLANK:
		return $Building.get_output_pile()
	if type == CoordinationManager.ResourceType.BRICK:
		return $BrickPile
	return null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_map = map
	var builder := BuilderScene.instantiate() as Builder
	builder.position = position + Vector2(0, _map.get_tile_size().y / 2.0)
	builder.setup(self, _map, coordination_manager)
	spawn_parent.add_child(builder)
	var plank_pile: ResourcePile = $Building.get_output_pile()
	plank_pile.setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	plank_pile.add_resource(PlankScene)
	plank_pile.add_resource(PlankScene)
	var brick_pile: ResourcePile = $BrickPile
	brick_pile.setup(coordination_manager, CoordinationManager.ResourceType.BRICK)
	brick_pile.add_resource(BrickScene)

