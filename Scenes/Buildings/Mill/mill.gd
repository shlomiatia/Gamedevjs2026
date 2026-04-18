extends Node2D

const WHEEL_ROTATION_SPEED := TAU / 10.0

var _is_milling := false

func validate_placement(top_left: Vector2i, _map: Map) -> bool:
	return top_left.y == Map.RIVER_ROW + 1

func set_milling(val: bool) -> void:
	_is_milling = val

func set_construction_progress(progress: float) -> void:
	var sprite: Sprite2D = $WatermillSprite
	if sprite.texture == null:
		return
	var tex_height := float(sprite.texture.get_height())
	var tex_width := float(sprite.texture.get_width())
	var shown_height := tex_height * progress
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, tex_height - shown_height, tex_width, shown_height)
	sprite.position = Vector2(0.0, -shown_height / 2.0)

func complete_construction() -> void:
	var sprite: Sprite2D = $WatermillSprite
	sprite.region_enabled = false
	if sprite.texture:
		sprite.position = Vector2(0.0, -float(sprite.texture.get_height()) / 2.0)

func _process(delta: float) -> void:
	if _is_milling:
		$WatermillSprite.rotation += WHEEL_ROTATION_SPEED * delta
