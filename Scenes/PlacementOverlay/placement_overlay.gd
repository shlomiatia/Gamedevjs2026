class_name PlacementOverlay
extends Node2D

var _invalid_rects: Array[Rect2] = []
var _arrow_dir: Vector2 = Vector2.ZERO
var _show_arrow: bool = false
var _footprint: Rect2 = Rect2()
var _footprint_valid: bool = true
var _has_footprint: bool = false

# Settings
@export var center_text: String = ""
@export var font_size: int = 18

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
    queue_redraw()

func clear() -> void:
    _invalid_rects = []
    _show_arrow = false
    _has_footprint = false
    center_text = ""
    queue_redraw()

func _draw() -> void:
    var vt := get_viewport().get_canvas_transform()
    var sc := vt.get_scale().x
    var vp_size := get_viewport_rect().size
    var center := vp_size * 0.5

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
        var dir := _arrow_dir.normalized()
        var start := center + dir * 32.0
        var tip := start + dir * 100.0
        var ang := dir.angle()
        
        draw_line(start, tip, Color.WHITE, 4.0)
        
        var side := dir.rotated(PI / 2)
        var nudge := -1.0
        
        var left_start = tip + side * nudge
        draw_line(left_start, left_start + Vector2.from_angle(ang + 2.5) * 20.0, Color.WHITE, 4.0)
        
        var right_start = tip - side * nudge
        draw_line(right_start, right_start + Vector2.from_angle(ang - 2.5) * 20.0, Color.WHITE, 4.0)

    if center_text != "":
        var font = ThemeDB.fallback_font
        var t_size = font.get_string_size(center_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
        var t_pos = center + Vector2(-t_size.x / 2, t_size.y / 4)
        draw_string(font, t_pos, center_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)