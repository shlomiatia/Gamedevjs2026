class_name BuilderHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "BuilderHut"

const BuilderScene = preload("res://Scenes/Workers/Builder/Builder.tscn")
const LogScene = preload("res://Scenes/Resources/Log/Log.tscn")

func on_placed(spawn_parent: Node2D, tile_size: Vector2i) -> void:
    var builder := BuilderScene.instantiate()
    builder.position = position + Vector2(0, tile_size.y / 2.0)
    spawn_parent.add_child(builder)

    $OutputPile.add_resource(LogScene)
    $OutputPile.add_resource(LogScene)
