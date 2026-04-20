class_name TutorialOverlay
extends Control

var highlight_rect: Rect2 = Rect2()
var has_highlight: bool = false

const OVERLAY_COLOR := Color(0.0, 0.0, 0.0, 0.72)
const BORDER_COLOR := Color(1.0, 0.85, 0.1, 1.0)
const BORDER_WIDTH := 2.0
const PAD := 6.0

const NUM_RINGS := 4
const RING_MAX_EXTRA := 10.0 # how far out the rings start
const RING_SPEED := 0.6 # cycles per second

var _anim_time: float = 0.0

func _process(delta: float) -> void:
    if has_highlight:
        _anim_time += delta * RING_SPEED * TAU
        queue_redraw()

func _draw() -> void:
    var vr := get_viewport_rect()
    if not has_highlight:
        draw_rect(vr, OVERLAY_COLOR)
        return

    var h := Rect2(
        highlight_rect.position - Vector2(PAD, PAD),
        highlight_rect.size + Vector2(PAD * 2.0, PAD * 2.0)
    )

    # Dark cutout regions
    draw_rect(Rect2(0.0, 0.0, vr.size.x, maxf(0.0, h.position.y)), OVERLAY_COLOR)
    draw_rect(Rect2(0.0, h.end.y, vr.size.x, maxf(0.0, vr.size.y - h.end.y)), OVERLAY_COLOR)
    draw_rect(Rect2(0.0, h.position.y, maxf(0.0, h.position.x), h.size.y), OVERLAY_COLOR)
    draw_rect(Rect2(h.end.x, h.position.y, maxf(0.0, vr.size.x - h.end.x), h.size.y), OVERLAY_COLOR)

    # Shrinking rings: each ring travels from outer edge inward to h, fading in
    for i in NUM_RINGS:
        var phase := _anim_time - i * (TAU / NUM_RINGS)
        var t := 0.5 + 0.5 * sin(phase) # 0 = far out, 1 = at highlight
        var extra := RING_MAX_EXTRA * (1.0 - t)
        var alpha := t * 0.75
        var ring := Rect2(
            h.position - Vector2(extra, extra),
            h.size + Vector2(extra * 2.0, extra * 2.0)
        )
        draw_rect(ring, Color(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b, alpha), false, 1.5)

    # Solid border on the highlight itself
    draw_rect(h, BORDER_COLOR, false, BORDER_WIDTH)
