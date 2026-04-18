extends Node2D

var _map: Map = null

func setup(map: Map) -> void:
	_map = map

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		visible = not visible

func _draw() -> void:
	if _map == null:
		return
	var tile_size := _map.get_tile_size()
	var half := Vector2(tile_size) * 0.5
	for x in Map.LEVEL_WIDTH:
		for y in Map.LEVEL_HEIGHT:
			var tile := Vector2i(x, y)
			var center := _map.tile_to_world(tile)
			var occ: int = _map.occupied_tiles.get(tile, 0)
			var color: Color
			match occ:
				Map.OccupiedType.BLOCK_WORKERS:
					color = Color(1.0, 1.0, 0.0, 0.35)
				Map.OccupiedType.BLOCK_BUILDING:
					color = Color(1.0, 0.0, 0.0, 0.25)
				_:
					color = Color(0.0, 1.0, 0.0, 0.15)
			draw_rect(Rect2(center - half, Vector2(tile_size)), color)
