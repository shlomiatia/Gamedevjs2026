class_name WoodcutterHut
extends Building

const SIZE_X := 5
const SIZE_Y := 3
const BUILDING_NAME := "WoodcutterHut"
const SEARCH_RADIUS := 300.0

const WoodcutterScene = preload("res://Scenes/Workers/Woodcutter/Woodcutter.tscn")

var _spawn_parent: Node2D = null
var _map: Map = null

func on_placed(spawn_parent: Node2D, map: Map) -> void:
    _spawn_parent = spawn_parent
    _map = map
    $NameLabel.visible = false
    $InputPile.visible = false
    $OutputPile.visible = false
    var coordination_manager := spawn_parent.get_node("CoordinationManager")
    $OutputPile.setup(coordination_manager, CoordinationManager.ResourceType.LOG)
    set_construction_progress(0.01)

func _draw() -> void:
    var r := SEARCH_RADIUS
    draw_rect(Rect2(-r, -r, r * 2.0, r * 2.0), Color(0.4, 0.85, 0.4, 0.6), false, 2.0)

func complete_construction() -> void:
    $Sprite2D.region_enabled = false
    $Sprite2D.position = Vector2(0, -104)
    $NameLabel.visible = true
    $InputPile.visible = true
    $OutputPile.visible = true
    var woodcutter := WoodcutterScene.instantiate() as Woodcutter
    woodcutter.position = position + Vector2(0.0, float(_map.get_tile_size().y) * 0.5)
    woodcutter.setup(self, _map)
    _spawn_parent.add_child(woodcutter)
