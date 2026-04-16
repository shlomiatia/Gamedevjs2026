class_name ResourcePile
extends Node2D

const SPACE := 8

func add_resource(scene: PackedScene) -> void:
    var resource := scene.instantiate()
    resource.position = Vector2(0, -get_child_count() * SPACE)
    add_child(resource)
