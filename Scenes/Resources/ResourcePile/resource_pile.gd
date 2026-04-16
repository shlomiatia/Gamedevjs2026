class_name ResourcePile
extends Node2D

const SPACE := 8

var _reserved_by: Array = []
var _coordination_manager: Node = null
var _resource_type: int = -1

func setup(coordination_manager: Node, resource_type: int) -> void:
	_coordination_manager = coordination_manager
	_resource_type = resource_type

func add_resource(scene: PackedScene) -> void:
	var resource := scene.instantiate()
	resource.position = Vector2(0, -get_child_count() * SPACE)
	add_child(resource)
	_notify_new_resource()

func add_existing_resource(node: Node2D) -> void:
	node.position = Vector2(0, -get_child_count() * SPACE)
	add_child(node)
	_notify_new_resource()

func _notify_new_resource() -> void:
	if _coordination_manager != null and _resource_type >= 0:
		_coordination_manager.notify_free_resource(_resource_type)

func _cleanup_reservations() -> void:
	_reserved_by = _reserved_by.filter(func(c): return is_instance_valid(c))

func free_count() -> int:
	_cleanup_reservations()
	return get_child_count() - _reserved_by.size()

func reserve(collector) -> void:
	_cleanup_reservations()
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
