class_name BuildingComponent
extends Node2D

const SPRITE_OFFSET_Y := -104.0
const SIZE := Vector2i(5, 2)

@export var has_mill: bool = false
@export var building_name: String = ""
@export var building_texture: Texture2D = null
@export var building_material: Material = null

var _map: Map = null
var _top_left: Vector2i
var _nav_hole: PackedVector2Array

func _ready() -> void:
    $Fence/Label.text = building_name
    $Fence/Label.label_settings = preload("res://Themes/label_medium.tres")
    $Mill.visible = false
    $Fence.visible = false
    if building_texture != null:
        $Sprite2D.texture = building_texture
    if building_material != null:
        $Sprite2D.material = building_material
        if has_mill:
            $Mill.get_node("WatermillSprite").material = building_material

func start_construction() -> void:
    $Fence.visible = true
    set_construction_progress(0.0)

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

func register_on_map(map: Map, top_left: Vector2i) -> void:
    _map = map
    _top_left = top_left
    map.set_occupied_tiles_rect(top_left, SIZE, Map.OccupiedType.BLOCK_WORKERS)
    map.set_occupied_ring(top_left, SIZE, Map.OccupiedType.BLOCK_BUILDING)
    var ts := map.get_tile_size()
    var hw := SIZE.x * ts.x * 0.5
    var h := SIZE.y * ts.y
    var obstacle := NavigationObstacle2D.new()
    obstacle.avoidance_enabled = true
    obstacle.vertices = PackedVector2Array([
        Vector2(-hw, -h), Vector2(hw, -h), Vector2(hw, 0.0), Vector2(-hw, 0.0)
    ])
    get_parent().add_child(obstacle)
    var p: Vector2 = (get_parent() as Node2D).position
    var e := 4.0
    _nav_hole = map.add_nav_hole(PackedVector2Array([
        p + Vector2(-hw - e, -h - e), p + Vector2(-hw - e, e),
        p + Vector2(hw + e, e), p + Vector2(hw + e, -h - e)
    ]))

func unregister_from_map() -> void:
    if _map == null:
        return
    _map.clear_occupied_tiles_rect(_top_left, SIZE)
    _map.clear_occupied_ring(_top_left, SIZE)
    _map.remove_nav_hole(_nav_hole)
    _map = null

func _on_button_pressed() -> void:
    $Fence/Button.disabled = true
    var parent := get_parent()
    var cm: CoordinationManager = parent._coordination_manager
    var saved_map := _map
    unregister_from_map()
    # Re-apply rings for remaining buildings so tiles shared with neighbors are preserved
    for b in cm.buildings:
        if b != parent:
            var bc := b.get_node_or_null("Building") as BuildingComponent
            if bc != null and bc._map != null:
                saved_map.set_occupied_ring(bc._top_left, BuildingComponent.SIZE, Map.OccupiedType.BLOCK_BUILDING)
    cm.cancel_construction(parent)
    parent.queue_free()

func remove_cancel_button() -> void:
    var button := get_node_or_null("Fence/Button")
    if button:
        button.queue_free()
