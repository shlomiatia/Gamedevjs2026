class_name Mountain
extends Node2D

const CoalScene = preload("res://Scenes/Resources/Coal/Coal.tscn")
const IronOreScene = preload("res://Scenes/Resources/IronOre/IronOre.tscn")
const OreTexture = preload("res://Textures/ore.png")

const COAL_THRESHOLD := 0.25
const IRON_THRESHOLD := 0.50

var _coal_mat: ShaderMaterial
var _iron_mat: ShaderMaterial

func setup(level_width: int, level_height: int, tile_size: Vector2i) -> void:
	var coal_inst := CoalScene.instantiate()
	_coal_mat = coal_inst.get_node("Sprite2D").material as ShaderMaterial
	coal_inst.free()
	var iron_inst := IronOreScene.instantiate()
	_iron_mat = iron_inst.get_node("Sprite2D").material as ShaderMaterial
	iron_inst.free()

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
