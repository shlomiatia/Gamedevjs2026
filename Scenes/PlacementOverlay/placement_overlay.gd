class_name PlacementOverlay
extends Node2D

var _invalid_rects: Array[Rect2] = []
var _arrow_world_pos: Vector2 = Vector2.ZERO
var _show_arrow: bool = false

func show_rects(rects: Array[Rect2]) -> void:
	_invalid_rects = rects
	queue_redraw()

func set_arrow(world_pos: Vector2, enabled: bool) -> void:
	_arrow_world_pos = world_pos
	_show_arrow = enabled
	queue_redraw()

func clear() -> void:
	_invalid_rects = []
	_show_arrow = false
	queue_redraw()

func _draw() -> void:
	if _invalid_rects.is_empty():
		return
	var vt := get_viewport().get_canvas_transform()
	var sc := vt.get_scale().x
	var color := Color(0.1, 0.1, 0.1, 0.5)
	for rect in _invalid_rects:
		var sp := vt * rect.position
		draw_rect(Rect2(sp, rect.size * sc), color)

	if _show_arrow:
		var vp_size := get_viewport_rect().size
		var center := vp_size * 0.5
		var target_screen := vt * _arrow_world_pos
		var dir := (target_screen - center).normalized()
		var tip := center + dir * 100.0
		draw_line(center, tip, Color.YELLOW, 4.0)
		var ang := dir.angle()
		draw_line(tip, tip + Vector2.from_angle(ang + 2.5) * 20.0, Color.YELLOW, 4.0)
		draw_line(tip, tip + Vector2.from_angle(ang - 2.5) * 20.0, Color.YELLOW, 4.0)
