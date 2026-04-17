class_name Sawmill
extends Node2D

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "Sawmill"

const SawmillerScene = preload("res://Scenes/Workers/Sawmiller/Sawmiller.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, _forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	$Building.get_output_pile().setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	$Building.start_construction()

func set_construction_progress(progress: float) -> void:
	$Building.set_construction_progress(progress)

func complete_construction() -> void:
	$Building.complete_construction()
	var sawmiller := SawmillerScene.instantiate() as Sawmiller
	sawmiller.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	sawmiller.setup(self, _map, _coordination_manager)
	_spawn_parent.add_child(sawmiller)

func on_worker_died() -> void:
	$Building.on_worker_died()

func set_milling(val: bool) -> void:
	$Building.set_milling(val)
