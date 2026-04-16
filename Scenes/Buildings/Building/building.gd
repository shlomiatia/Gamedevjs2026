class_name Building
extends Node2D

@export var building_name: String = "":
	set(value):
		building_name = value
		if is_node_ready():
			$NameLabel.text = value

func _ready() -> void:
	$NameLabel.text = building_name

func on_placed(_spawn_parent: Node2D, _map: Map) -> void:
	pass

func set_construction_progress(progress: float) -> void:
	var sprite: Sprite2D = $Sprite2D
	if sprite.texture == null:
		return
	var tex_height := float(sprite.texture.get_height())
	var tex_width := float(sprite.texture.get_width())
	var shown_height := tex_height * progress
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, tex_height - shown_height, tex_width, shown_height)
	var original_bottom_y := -104.0 + tex_height / 2.0
	sprite.position = Vector2(0.0, original_bottom_y - shown_height / 2.0)

func complete_construction() -> void:
	pass
