class_name PlacementOverlay
extends Node2D

var _arrow_dir: Vector2 = Vector2.ZERO
var _show_arrow: bool = false

@export var center_text: String = ""
@export var font_size: int = 18

var _invalid_layer: TileMapLayer = null
var _footprint_layer: TileMapLayer = null

func setup(map: Node2D) -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(32, 32)
	source.create_tile(Vector2i(0, 0))
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	tileset.add_source(source, 0)

	_invalid_layer = TileMapLayer.new()
	_invalid_layer.tile_set = tileset
	_invalid_layer.modulate = Color(0.1, 0.1, 0.1, 0.5)
	_invalid_layer.z_index = 5
	map.add_child(_invalid_layer)

	_footprint_layer = TileMapLayer.new()
	_footprint_layer.tile_set = tileset
	_footprint_layer.z_index = 6
	map.add_child(_footprint_layer)

func show_tiles(invalid_tiles: Array[Vector2i]) -> void:
	if _invalid_layer == null:
		return
	_invalid_layer.clear()
	for tile in invalid_tiles:
		_invalid_layer.set_cell(tile, 0, Vector2i(0, 0))

func set_footprint(top_left: Vector2i, size: Vector2i, valid: bool) -> void:
	if _footprint_layer == null:
		return
	_footprint_layer.clear()
	_footprint_layer.modulate = Color(0, 0.85, 0, 0.5) if valid else Color(0.85, 0, 0, 0.5)
	for dx in size.x:
		for dy in size.y:
			_footprint_layer.set_cell(Vector2i(top_left.x + dx, top_left.y + dy), 0, Vector2i(0, 0))

func set_arrow(direction: Vector2, enabled: bool) -> void:
	_arrow_dir = direction
	_show_arrow = enabled
	queue_redraw()

func clear() -> void:
	if _invalid_layer != null:
		_invalid_layer.clear()
	if _footprint_layer != null:
		_footprint_layer.clear()
	_show_arrow = false
	center_text = ""
	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size
	var center := vp_size * 0.5

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
