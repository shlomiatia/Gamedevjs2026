class_name PlacementOverlay
extends Node2D

var _invalid_rects: Array[Rect2] = []
var _arrow_dir: Vector2 = Vector2.ZERO
var _show_arrow: bool = false
var _footprint: Rect2 = Rect2()
var _footprint_valid: bool = true
var _has_footprint: bool = false

func show_rects(rects: Array[Rect2]) -> void:
	_invalid_rects = rects
	queue_redraw()

func set_arrow(direction: Vector2, enabled: bool) -> void:
	_arrow_dir = direction
	_show_arrow = enabled
	queue_redraw()

func set_footprint(rect: Rect2, valid: bool) -> void:
	_footprint = rect
	_footprint_valid = valid
	_has_footprint = true

func clear() -> void:
	_invalid_rects = []
	_show_arrow = false
	_has_footprint = false
	queue_redraw()

func _draw() -> void:
	var vt := get_viewport().get_canvas_transform()
	var sc := vt.get_scale().x

	if _has_footprint:
		var fp := vt * _footprint.position
		var fs := _footprint.size * sc
		var fc := Color(0, 0.85, 0, 0.3) if _footprint_valid else Color(0.85, 0, 0, 0.3)
		var bc := Color(0, 0.85, 0, 0.9) if _footprint_valid else Color(0.85, 0, 0, 0.9)
		draw_rect(Rect2(fp, fs), fc)
		draw_rect(Rect2(fp, fs), bc, false, 2.0)

	if not _invalid_rects.is_empty():
		var color := Color(0.1, 0.1, 0.1, 0.5)
		for rect in _invalid_rects:
			var sp := vt * rect.position
			draw_rect(Rect2(sp, rect.size * sc), color)

	if _show_arrow and _arrow_dir != Vector2.ZERO:
		var vp_size := get_viewport_rect().size
		var center := vp_size * 0.5
		var dir := _arrow_dir.normalized()
		var tip := center + dir * 100.0
		draw_line(center, tip, Color.YELLOW, 4.0)
		var ang := dir.angle()
		draw_line(tip, tip + Vector2.from_angle(ang + 2.5) * 20.0, Color.YELLOW, 4.0)
		draw_line(tip, tip + Vector2.from_angle(ang - 2.5) * 20.0, Color.YELLOW, 4.0)
