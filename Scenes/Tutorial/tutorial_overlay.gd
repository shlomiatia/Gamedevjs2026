class_name TutorialOverlay
extends Control

var highlight_rect: Rect2 = Rect2()
var has_highlight: bool = false

const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.72)
const BORDER_COLOR := Color(1.0, 0.85, 0.1, 1.0)
const BORDER_WIDTH := 2.0
const PAD := 6.0

func _draw() -> void:
    var vr := get_viewport_rect()
    if not has_highlight:
        draw_rect(vr, OVERLAY_COLOR)
        return
    var h := Rect2(
        highlight_rect.position - Vector2(PAD, PAD),
        highlight_rect.size + Vector2(PAD * 2.0, PAD * 2.0)
    )
    draw_rect(Rect2(0.0, 0.0, vr.size.x, maxf(0.0, h.position.y)), OVERLAY_COLOR)
    draw_rect(Rect2(0.0, h.end.y, vr.size.x, maxf(0.0, vr.size.y - h.end.y)), OVERLAY_COLOR)
    draw_rect(Rect2(0.0, h.position.y, maxf(0.0, h.position.x), h.size.y), OVERLAY_COLOR)
    draw_rect(Rect2(h.end.x, h.position.y, maxf(0.0, vr.size.x - h.end.x), h.size.y), OVERLAY_COLOR)
    draw_rect(h, BORDER_COLOR, false, BORDER_WIDTH)
