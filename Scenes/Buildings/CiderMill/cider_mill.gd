class_name CiderMill
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "CiderMill"

const CiderMillerScene = preload("res://Scenes/Workers/CiderMiller/CiderMiller.tscn")

const WHEEL_ROTATION_SPEED := TAU / 10.0

var _is_milling := false

func set_milling(val: bool) -> void:
	_is_milling = val

func _process(delta: float) -> void:
	if _is_milling:
		$WatermillSprite.rotation += WHEEL_ROTATION_SPEED * delta

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, forest: Forest) -> void:
	super.on_placed(spawn_parent, map, coordination_manager, forest)
	$OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.CIDER)
	_start_construction()

func complete_construction() -> void:
	super.complete_construction()
	var miller := CiderMillerScene.instantiate() as CiderMiller
	miller.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
	miller.setup(self, _map, _coordination_manager)
	_spawn_parent.add_child(miller)
