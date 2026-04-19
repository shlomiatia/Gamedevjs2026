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
var _spawn_pos: Vector2
var _plank_pile: ResourcePile
var _brick_pile: ResourcePile

func get_pile_for_type(type: int) -> ResourcePile:
	if type == CoordinationManager.ResourceType.PLANK:
		return _plank_pile
	if type == CoordinationManager.ResourceType.BRICK:
		return _brick_pile
	return null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_map = map
	_spawn_parent = spawn_parent
	_coordination_manager = coordination_manager
	_placed_count += 1

	_plank_pile = $Building.get_output_pile()
	_brick_pile = $BrickPile
	_plank_pile.setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	_brick_pile.setup(coordination_manager, CoordinationManager.ResourceType.BRICK)

	var tiles := map.find_building_spawn_tiles(position, Vector2i(SIZE_X, SIZE_Y), 3)
	_spawn_pos = map.tile_to_world(tiles[0])
	_plank_pile.reparent(spawn_parent)
	_plank_pile.global_position = map.tile_to_world(tiles[1])
	_brick_pile.reparent(spawn_parent)
	_brick_pile.global_position = map.tile_to_world(tiles[2])

	if _placed_count == 1:
		_plank_pile.add_resource(PlankScene)
		_plank_pile.add_resource(PlankScene)
		_brick_pile.add_resource(BrickScene)
		_spawn_builder()
	else:
		_plank_pile.visible = false
		_brick_pile.visible = false
		$Building.start_construction()
		coordination_manager.queue_construction(self)

func complete_construction() -> void:
	$Building.complete_construction()
	_plank_pile.visible = true
	_brick_pile.visible = true
	_spawn_builder()

func _spawn_builder() -> void:
	var builder := BuilderScene.instantiate() as Builder
	builder.position = _spawn_pos
	builder.setup(self, _map, _coordination_manager)
	_spawn_parent.add_child(builder)
