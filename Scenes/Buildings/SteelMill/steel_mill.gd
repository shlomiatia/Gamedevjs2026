class_name SteelMill
extends Node2D

const SIZE_X := 5
const SIZE_Y := 2
const BUILDING_NAME := "SteelMill"
const CONSTRUCTION_RESOURCE_TYPE := CoordinationManager.ResourceType.BRICK

const KilnWorkerScene = preload("res://Scenes/Workers/KilnWorker/KilnWorker.tscn")
const IronBarScene = preload("res://Scenes/Resources/IronBar/IronBar.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null

func get_pile_for_type(type: int) -> ResourcePile:
	return $Building.get_output_pile() if type == CoordinationManager.ResourceType.IRON_BAR else null

func validate_placement(top_left: Vector2i, map: Map) -> bool:
	return $Building.validate_placement(top_left, map)

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	$Building.get_output_pile().setup(coordination_manager, CoordinationManager.ResourceType.IRON_BAR)
	$Building.start_construction()
	coordination_manager.queue_construction(self)

func set_smoking(value: bool) -> void:
	($Smoke as CPUParticles2D).emitting = value

func complete_construction() -> void:
	$Building.complete_construction()
	var worker := KilnWorkerScene.instantiate() as KilnWorker
	worker.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	worker.setup(self, _map, _coordination_manager, IronBarScene, CoordinationManager.ResourceType.IRON_ORE, CoordinationManager.ResourceType.COAL)
	_spawn_parent.add_child(worker)
