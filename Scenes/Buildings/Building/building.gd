class_name BuildingComponent
extends Node2D

const SPRITE_OFFSET_Y := -104.0

@export var has_mill: bool = false
@export var building_name: String = ""
@export var building_texture: Texture2D = null
@export var building_material: Material = null

func _ready() -> void:
    $Fence/Label.text = building_name
    $Mill.visible = false
    if building_texture != null:
        $Sprite2D.texture = building_texture
    if building_material != null:
        $Sprite2D.material = building_material
        if has_mill:
            $Mill.get_node("WatermillSprite").material = building_material

func start_construction() -> void:
    set_construction_progress(0.00)

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
    if has_mill:
        $Mill.visible = true
        $Mill.set_construction_progress(progress)
    if progress > 0.0:
        $Fence/Button.hide()
        
func complete_construction() -> void:
    $Sprite2D.region_enabled = false
    $Sprite2D.position = Vector2(0, SPRITE_OFFSET_Y)
    var tween := create_tween()
    tween.tween_property($Fence, "modulate:a", 0.0, 1.0)
    tween.tween_callback($Fence.queue_free)
    if has_mill:
        $Mill.complete_construction()

func on_worker_died() -> void:
    get_parent().modulate = Color(0.45, 0.45, 0.45)

func set_milling(val: bool) -> void:
    if has_mill:
        $Mill.set_milling(val)

func validate_placement(top_left: Vector2i, map: Map) -> bool:
    if has_mill:
        return $Mill.validate_placement(top_left, map)
    return true

func get_output_pile() -> ResourcePile:
    return $OutputPile as ResourcePile


func _on_button_pressed() -> void:
    $Fence/Button.hide()
    get_parent()._coordination_manager.cancel_construction(get_parent())
    var tween := create_tween()
    tween.tween_property($Fence, "modulate:a", 0.0, 1.0)
    tween.tween_callback(get_parent().queue_free)
