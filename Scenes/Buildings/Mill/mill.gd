extends Node2D

const MAX_WHEEL_SPEED := TAU / 10.0
# Adjust these to change how "heavy" the wheel feels
const ACCELERATION_SMOOTHING := 2.0

var _target_speed := 0.0
var _current_speed := 0.0
var _is_milling := false

func validate_placement(top_left: Vector2i, _map: Map) -> bool:
	return top_left.y == Map.RIVER_ROW + 2

func set_milling(val: bool) -> void:
	_is_milling = val
	# Set the target speed based on the milling state
	_target_speed = MAX_WHEEL_SPEED if val else 0.0
         
func _process(delta: float) -> void:
	# Gradually move current_speed toward target_speed
	_current_speed = lerp(_current_speed, _target_speed, ACCELERATION_SMOOTHING * delta)
	
	# Apply the rotation if the wheel is actually moving
	if not is_zero_approx(_current_speed):
		$WatermillSprite.rotation += _current_speed * delta

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