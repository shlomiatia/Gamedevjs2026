class_name SheepFarm
extends Node2D

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "SheepFarm"
const SHEEP_COUNT := 3

const SheepFarmerScene = preload("res://Scenes/Workers/SheepFarmer/SheepFarmer.tscn")
const SheepScene = preload("res://Scenes/Sheep/Sheep.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _sheep: Array[Sheep] = []

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	$Building.get_output_pile().setup(coordination_manager, CoordinationManager.ResourceType.WOOL)
	$Building.start_construction()

func set_construction_progress(progress: float) -> void:
	$Building.set_construction_progress(progress)

func complete_construction() -> void:
	$Building.complete_construction()
	_spawn_sheep()
	var farmer := SheepFarmerScene.instantiate() as SheepFarmer
	farmer.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	farmer.setup(self, _map, _coordination_manager)
	_spawn_parent.add_child(farmer)

func on_worker_died() -> void:
	$Building.on_worker_died()

func find_unsheared_sheep() -> Sheep:
	for sheep in _sheep:
		if is_instance_valid(sheep) and not sheep.is_sheared and not sheep.targeted:
			return sheep
	return null

func _spawn_sheep() -> void:
	for i in SHEEP_COUNT:
		var sheep := SheepScene.instantiate() as Sheep
		var offset := Vector2(randf_range(-48.0, 48.0), randf_range(-16.0, 16.0))
		sheep.position = position + offset
		_spawn_parent.add_child(sheep)
		_sheep.append(sheep)
