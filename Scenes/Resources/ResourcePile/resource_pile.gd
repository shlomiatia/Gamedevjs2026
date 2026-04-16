class_name ResourcePile
extends Node2D

const SPACE := 8

var _reserved_by: Array = []

func add_resource(scene: PackedScene) -> void:
	var resource := scene.instantiate()
	resource.position = Vector2(0, -get_child_count() * SPACE)
	add_child(resource)

func add_existing_resource(node: Node2D) -> void:
	node.position = Vector2(0, -get_child_count() * SPACE)
	add_child(node)

func free_count() -> int:
	return get_child_count() - _reserved_by.size()

func reserve(collector) -> void:
	_reserved_by.append(collector)

func collect(collector) -> Node2D:
	var idx := _reserved_by.find(collector)
	if idx >= 0:
		_reserved_by.remove_at(idx)
	if get_child_count() == 0:
		return null
	var node := get_child(get_child_count() - 1) as Node2D
	remove_child(node)
	return node
