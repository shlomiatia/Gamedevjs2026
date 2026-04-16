class_name ResourceCollectorWorker
extends Node2D

var _target_pile: ResourcePile = null
var _coordination_manager: Node = null

func go_collect_resource(pile: ResourcePile) -> void:
	_target_pile = pile
	$Worker.navigate_to(pile.global_position)
	_set_collecting_state()

func _set_collecting_state() -> void:
	pass
