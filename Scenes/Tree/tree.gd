class_name GameTree
extends Node2D

var targeted := false
var has_apples := true
var apple_targeted := false

func _ready() -> void:
	$ApplesSprite.visible = has_apples

func set_chop_progress(progress: float) -> void:
	rotation_degrees = progress * 90.0

func remove_apples() -> void:
	has_apples = false
	apple_targeted = false
	$ApplesSprite.visible = false
