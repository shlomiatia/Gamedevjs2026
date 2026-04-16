class_name BuilderHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "BuilderHut"

const BuilderScene = preload("res://Scenes/Workers/Builder/Builder.tscn")
const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

func on_placed(spawn_parent: Node2D, tile_size: Vector2i) -> void:
	var building_manager: Node2D = spawn_parent.get_node("BuildingManager")
	var grass_layer: TileMapLayer = spawn_parent.get_node("Grass")

	var builder := BuilderScene.instantiate() as Builder
	builder.position = position + Vector2(0, tile_size.y / 2.0)
	builder.setup(self, building_manager, grass_layer, tile_size)
	spawn_parent.add_child(builder)
	building_manager.register_builder(builder)

	$OutputPile.add_resource(LogScene)
	$OutputPile.add_resource(LogScene)
