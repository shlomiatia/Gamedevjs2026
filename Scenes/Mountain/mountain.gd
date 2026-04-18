class_name Mountain
extends Node2D

const OreTexture = preload("res://Textures/ore.png")

func setup(level_width: int, level_height: int, tile_size: Vector2i) -> void:
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
				ore.offset = Vector2(0.0, -ore_half_h)
				ore.flip_h = randf() < 0.5
				ore.position = tile_center + Vector2(
					randf_range(-tile_size.x * 0.4, tile_size.x * 0.4),
					randf_range(-tile_size.y * 0.4, tile_size.y * 0.4)
				)
				ore.scale = Vector2.ONE * randf_range(0.5, 2.0)
				add_child(ore)
