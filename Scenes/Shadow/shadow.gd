extends Node2D

@export var skew: float = 0.4
@export var scale_y: float = 0.35
@export var alpha: float = 0.45

var _inner: Sprite2D
var _last_region: Rect2 = Rect2()
var _atlas_cache: AtlasTexture = null

func _ready() -> void:
	show_behind_parent = true
	_inner = Sprite2D.new()
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://Shaders/shadow.gdshader")
	mat.set_shader_parameter("alpha", alpha)
	_inner.material = mat
	add_child(_inner)

func _process(_delta: float) -> void:
	var par := get_parent()
	var tex: Texture2D = null
	var flip_h := false

	if par is AnimatedSprite2D:
		var asp := par as AnimatedSprite2D
		if asp.sprite_frames != null and asp.animation != &"":
			tex = asp.sprite_frames.get_frame_texture(asp.animation, asp.frame)
		flip_h = asp.flip_h
	elif par is Sprite2D:
		var sp := par as Sprite2D
		if sp.region_enabled:
			if _atlas_cache == null or _last_region != sp.region_rect:
				_atlas_cache = AtlasTexture.new()
				_atlas_cache.atlas = sp.texture
				_atlas_cache.region = sp.region_rect
				_last_region = sp.region_rect
			tex = _atlas_cache
		else:
			tex = sp.texture
		flip_h = sp.flip_h

	_inner.flip_h = flip_h

	if tex == null:
		_inner.texture = null
		return

	_inner.texture = tex
	var h := float(tex.get_height())
	# Inner sprite bottom sits at shadow origin (ground). It grows upward in shadow
	# space which maps to downward on screen because the shadow transform flips Y.
	_inner.position = Vector2(0.0, -h * 0.5)
	# Shadow transform: origin at sprite bottom, skewed and Y-flipped + compressed.
	transform = Transform2D(
		Vector2(1.0, 0.0),
		Vector2(skew, -scale_y),
		Vector2(0.0, h * 0.5)
	)
	(_inner.material as ShaderMaterial).set_shader_parameter("alpha", alpha)
