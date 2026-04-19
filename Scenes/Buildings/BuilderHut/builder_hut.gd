class_name BuilderHut
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "BuilderHut"

const BuilderScene = preload("res://Scenes/Workers/Builder/Builder.tscn")
const PlankScene = preload("res://Scenes/Resources/Plank/Plank.tscn")
const BrickScene = preload("res://Scenes/Resources/Brick/Brick.tscn")

static var _placed_count := 0

var _map: Map = null
var _spawn_parent: Node2D = null
var _coordination_manager: Node = null

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
	_spawn_parent = spawn_parent
	_coordination_manager = coordination_manager
	_placed_count += 1

	var plank_pile: ResourcePile = $Building.get_output_pile()
	plank_pile.setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	var brick_pile: ResourcePile = $BrickPile
	brick_pile.setup(coordination_manager, CoordinationManager.ResourceType.BRICK)

	if _placed_count == 1:
		plank_pile.add_resource(PlankScene)
		plank_pile.add_resource(PlankScene)
		brick_pile.add_resource(BrickScene)
		_spawn_builder()
	else:
		$Building.start_construction()
		coordination_manager.queue_construction(self)

func complete_construction() -> void:
	$Building.complete_construction()
	_spawn_builder()

func _spawn_builder() -> void:
	var builder := BuilderScene.instantiate() as Builder
	builder.position = position + Vector2(0, _map.get_tile_size().y / 2.0)
	builder.setup(self, _map, _coordination_manager)
	_spawn_parent.add_child(builder)
