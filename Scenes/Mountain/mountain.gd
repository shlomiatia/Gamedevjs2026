class_name Mountain
extends Node2D

const OreTexture = preload("res://Textures/ore.png")
const PaletteSwapShader = preload("res://Shaders/pallete_swap.gdshader")

const COAL_THRESHOLD := 0.25
const IRON_THRESHOLD := 0.50

var _coal_mat: ShaderMaterial
var _iron_mat: ShaderMaterial

func _make_coal_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PaletteSwapShader
	m.set_shader_parameter("is_disabled", false)
	m.set_shader_parameter("original_0", Color(0.68235, 0.27059, 0.29020, 1))
	m.set_shader_parameter("replace_0",  Color(0.15686, 0.09804, 0.18431, 1))
	m.set_shader_parameter("original_1", Color(0.54902, 0.19216, 0.19608, 1))
	m.set_shader_parameter("replace_1",  Color(0.07843, 0.05098, 0.09412, 1))
	m.set_shader_parameter("original_2", Color(0.32941, 0.13725, 0.13725, 1))
	m.set_shader_parameter("replace_2",  Color(0.0,     0.0,     0.0,     1))
	return m

func _make_iron_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = PaletteSwapShader
	m.set_shader_parameter("is_disabled", false)
	m.set_shader_parameter("original_0", Color(0.68235, 0.27059, 0.29020, 1))
	m.set_shader_parameter("replace_0",  Color(0.80784, 0.79216, 0.78824, 1))
	m.set_shader_parameter("original_1", Color(0.54902, 0.19216, 0.19608, 1))
	m.set_shader_parameter("replace_1",  Color(0.63137, 0.53333, 0.59216, 1))
	m.set_shader_parameter("original_2", Color(0.32941, 0.13725, 0.13725, 1))
	m.set_shader_parameter("replace_2",  Color(0.36471, 0.27451, 0.37647, 1))
	return m

func setup(level_width: int, level_height: int, tile_size: Vector2i) -> void:
	_coal_mat = _make_coal_material()
	_iron_mat = _make_iron_material()
	z_index = 100
	y_sort_enabled = true
	var ore_half_h := OreTexture.get_height() / 2.0
	for row in range(level_height - 5, level_height + 1):
		for x in level_width:
			var tile_center := Vector2(
				x * tile_size.x + tile_size.x * 0.5,
				row * tile_size.y + tile_size.y * 0.5
			)
			var count := randi_range(1, 4)
			for i in count:
				var ore := Sprite2D.new()
				ore.texture = OreTexture
				var r := randf()
				if r < COAL_THRESHOLD:
					ore.material = _coal_mat
				elif r < IRON_THRESHOLD:
					ore.material = _iron_mat
				# else: no material = clay/regular rock
				ore.offset = Vector2(0.0, -ore_half_h)
				ore.flip_h = randf() < 0.5
				ore.position = tile_center + Vector2(
					randf_range(-tile_size.x * 0.4, tile_size.x * 0.4),
					randf_range(-tile_size.y * 0.4, tile_size.y * 0.4)
				)
				ore.scale = Vector2.ONE * randf_range(0.5, 2.0)
				add_child(ore)
