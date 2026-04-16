class_name Sawmill
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "Sawmill"

const SawmillerScene = preload("res://Scenes/Workers/Sawmiller/Sawmiller.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null

func on_placed(spawn_parent: Node2D, map: Map) -> void:
	_spawn_parent = spawn_parent
	_map = map
	$NameLabel.visible = false
	$InputPile.visible = false
	$OutputPile.visible = false
	var coordination_manager := spawn_parent.get_node("CoordinationManager")
	$OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.PLANK)
	set_construction_progress(0.01)

func complete_construction() -> void:
	$Sprite2D.region_enabled = false
	$Sprite2D.position = Vector2(0, -104)
	$NameLabel.visible = true
	$InputPile.visible = true
	$OutputPile.visible = true
	var sawmiller := SawmillerScene.instantiate() as Sawmiller
	sawmiller.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	var coordination_manager := _spawn_parent.get_node("CoordinationManager")
	sawmiller.setup(self, _map, coordination_manager)
	_spawn_parent.add_child(sawmiller)
