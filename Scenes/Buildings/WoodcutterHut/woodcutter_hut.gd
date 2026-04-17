class_name WoodcutterHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "WoodcutterHut"

const WoodcutterScene = preload("res://Scenes/Workers/Woodcutter/Woodcutter.tscn")

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, forest: Forest) -> void:
	super.on_placed(spawn_parent, map, coordination_manager, forest)
	$OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.LOG)
	_start_construction()

func complete_construction() -> void:
	super.complete_construction()
	var woodcutter := WoodcutterScene.instantiate() as Woodcutter
	woodcutter.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	woodcutter.setup(self, _map, _forest)
	_spawn_parent.add_child(woodcutter)
