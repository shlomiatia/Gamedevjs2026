class_name AppleFarm
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "AppleFarm"
const SEARCH_RADIUS := 300.0

const AppleFarmerScene = preload("res://Scenes/Workers/AppleFarmer/AppleFarmer.tscn")

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node) -> void:
	super.on_placed(spawn_parent, map, coordination_manager)
	$OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.APPLE)
	_start_construction()

func _draw() -> void:
	var r := SEARCH_RADIUS
	draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), Color(0.85, 0.4, 0.4, 0.6), false, 2.0)

func complete_construction() -> void:
	super.complete_construction()
	var farmer := AppleFarmerScene.instantiate() as AppleFarmer
	farmer.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	farmer.setup(self, _map)
	_spawn_parent.add_child(farmer)
