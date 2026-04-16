class_name BuilderHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "BuilderHut"

const BuilderScene = preload("res://Scenes/Workers/Builder/Builder.tscn")
const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

func on_placed(spawn_parent: Node2D, map: Map) -> void:
	var coordination_manager := spawn_parent.get_node("CoordinationManager")
	var tile_size := map.get_tile_size()

	var builder := BuilderScene.instantiate() as Builder
	builder.position = position + Vector2(0, tile_size.y / 2.0)
	builder.setup(self, map, coordination_manager)
	spawn_parent.add_child(builder)

	$OutputPile.add_resource(LogScene)
	$OutputPile.add_resource(LogScene)
	coordination_manager.notify_free_resource(CoordinationManager.ResourceType.LOG)
	coordination_manager.notify_free_resource(CoordinationManager.ResourceType.LOG)
