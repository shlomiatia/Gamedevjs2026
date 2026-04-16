class_name WoodcutterHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "WoodcutterHut"

const WoodcutterScene = preload("res://Scenes/Workers/Woodcutter/Woodcutter.tscn")

var _spawn_parent: Node2D = null
var _tile_size: Vector2i

func on_placed(spawn_parent: Node2D, tile_size: Vector2i) -> void:
	_spawn_parent = spawn_parent
	_tile_size = tile_size
	$NameLabel.visible = false
	$InputPile.visible = false
	$OutputPile.visible = false
	set_construction_progress(0.01)

func set_construction_progress(progress: float) -> void:
	var sprite: Sprite2D = $Sprite2D
	if sprite.texture == null:
		return
	var tex_height := float(sprite.texture.get_height())
	var tex_width := float(sprite.texture.get_width())
	var shown_height := tex_height * progress
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, tex_height - shown_height, tex_width, shown_height)
	# Keep the bottom of the sprite fixed at y = -104 + tex_height/2
	var original_bottom_y := -104.0 + tex_height / 2.0
	sprite.position = Vector2(0.0, original_bottom_y - shown_height / 2.0)

func complete_construction() -> void:
	$Sprite2D.region_enabled = false
	$Sprite2D.position = Vector2(0, -104)
	$NameLabel.visible = true
	$InputPile.visible = true
	$OutputPile.visible = true
	var woodcutter := WoodcutterScene.instantiate()
	woodcutter.position = position + Vector2(0.0, float(_tile_size.y) * 0.5)
	_spawn_parent.add_child(woodcutter)
