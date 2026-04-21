class_name GameTree
extends Node2D

var targeted := false
var has_apples := true

var _map: Map = null
var _tile_pos: Vector2i

func setup(map: Map, tile_pos: Vector2i) -> void:
    _map = map
    _tile_pos = tile_pos
    _map.occupied_tiles[tile_pos] = Map.OccupiedType.BLOCK_BUILDING

func remove_from_map() -> void:
    _map.occupied_tiles.erase(_tile_pos)

func _ready() -> void:
    $ApplesSprite.visible = has_apples

func set_chop_progress(progress: float) -> void:
    rotation_degrees = Tween.interpolate_value(
        0.0,
        90.0,
        progress,
        1.0, # Total duration set to 1.0 for easy mapping
        Tween.TRANS_SINE,
        Tween.EASE_OUT
    )

func set_pick_progress(progress: float) -> void:
    $ApplesSprite.modulate.a = 1.0 - progress

func remove_apples() -> void:
    has_apples = false
    targeted = false
    $ApplesSprite.modulate.a = 1.0
    $ApplesSprite.visible = false
