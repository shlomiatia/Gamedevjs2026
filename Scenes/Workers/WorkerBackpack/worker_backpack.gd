class_name WorkerBackpack
extends Node

var _outer: Node2D = null
var _carried_resource: Node2D = null

func setup(outer: Node2D) -> void:
	_outer = outer

func carry(resource: Node2D) -> void:
	resource.position = Vector2(0, -48)
	_outer.add_child(resource)
	_carried_resource = resource

func carry_from_pile(pile: ResourcePile, collector: Node) -> void:
	carry(pile.collect(collector))

func drop() -> Node2D:
	assert(_carried_resource != null, "drop called when not carrying")
	var resource := _carried_resource
	_carried_resource = null
	_outer.remove_child(resource)
	return resource

func is_carrying() -> bool:
	return _carried_resource != null
