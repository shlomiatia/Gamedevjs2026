class_name BuilderHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "BuilderHut"

const BuilderScene = preload("res://Scenes/Workers/Builder/Builder.tscn")
const PlankScene = preload("res://Scenes/Resources/Plank/Plank.tscn")

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node) -> void:
	super.on_placed(spawn_parent, map, coordination_manager)
	var builder := BuilderScene.instantiate() as Builder
	builder.position = position + Vector2(0, _map.get_tile_size().y / 2.0)
	builder.setup(self, _map, coordination_manager)
	spawn_parent.add_child(builder)
	$OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	$OutputPile.add_resource(PlankScene)
	$OutputPile.add_resource(PlankScene)
