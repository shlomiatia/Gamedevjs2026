class_name Building
extends Node2D

const SPRITE_OFFSET_Y := -104.0

@export var building_name: String = "":
	set(value):
		building_name = value
		if is_node_ready():
			$NameLabel.text = value

var _spawn_parent: Node2D = null
var _map: Map = null
var _coordination_manager: Node = null
var _forest: Forest = null

func _ready() -> void:
	$NameLabel.text = building_name

func on_placed(spawn_parent: Node2D, map: Map, coordination_manager: Node, forest: Forest) -> void:
	_spawn_parent = spawn_parent
	_map = map
	_coordination_manager = coordination_manager
	_forest = forest

func _start_construction() -> void:
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
	var original_bottom_y := SPRITE_OFFSET_Y + tex_height / 2.0
	sprite.position = Vector2(0.0, original_bottom_y - shown_height / 2.0)

func on_worker_died() -> void:
	modulate = Color(0.45, 0.45, 0.45)

func complete_construction() -> void:
	$Sprite2D.region_enabled = false
	$Sprite2D.position = Vector2(0, SPRITE_OFFSET_Y)
	$NameLabel.visible = true
	$InputPile.visible = true
	$OutputPile.visible = true
