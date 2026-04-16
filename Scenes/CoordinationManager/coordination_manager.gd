class_name CoordinationManager
extends Node

var _builders: Array = []
var _construction_queue: Array = []

func register_builder(builder: Builder) -> void:
	_builders.append(builder)
	notify_idle_builder(builder)

func queue_construction(target: WoodcutterHut) -> void:
	var builder := _find_closest_free_builder(target.position)
	if builder != null:
		builder.assign_build_task(target)
	else:
		_construction_queue.append(target)

func notify_idle_builder(builder: Builder) -> void:
	if _construction_queue.is_empty():
		return
	var idx := _find_closest_construction_idx(builder.position)
	var target := _construction_queue[idx] as WoodcutterHut
	_construction_queue.remove_at(idx)
	builder.assign_build_task(target)

func _find_closest_free_builder(pos: Vector2) -> Builder:
	var closest: Builder = null
	var min_dist := INF
	for b in _builders:
		var builder := b as Builder
		if builder != null and builder.is_free():
			var d := builder.position.distance_to(pos)
			if d < min_dist:
				min_dist = d
				closest = builder
	return closest

func _find_closest_construction_idx(pos: Vector2) -> int:
	var best_idx := 0
	var min_dist := INF
	for i in _construction_queue.size():
		var hut := _construction_queue[i] as WoodcutterHut
		if hut != null:
			var d := hut.position.distance_to(pos)
			if d < min_dist:
				min_dist = d
				best_idx = i
	return best_idx
