class_name River
extends Node2D

const RIVER_FRAMES := 32
const RIVER_COLS := 6
const RIVER_FPS := 10.0

var _level_width := 0
var _river_row := 0
var _river_rows := 1
var _river_frame := 0
var _river_timer := 0.0

@onready var _layer: TileMapLayer = $Layer

func setup(level_width: int, river_row: int, river_rows: int = 1) -> void:
	_level_width = level_width
	_river_row = river_row
	_river_rows = river_rows
	for x in level_width:
		for r in river_rows:
			_layer.set_cell(Vector2i(x, river_row + r), 0, Vector2i(0, 0))

func _process(delta: float) -> void:
	_river_timer += delta
	if _river_timer >= 1.0 / RIVER_FPS:
		_river_timer -= 1.0 / RIVER_FPS
		_river_frame = (_river_frame + 1) % RIVER_FRAMES
		var col := _river_frame % RIVER_COLS
		var row: int = _river_frame / RIVER_COLS
		for x in _level_width:
			for r in _river_rows:
				_layer.set_cell(Vector2i(x, _river_row + r), 0, Vector2i(col, row))
