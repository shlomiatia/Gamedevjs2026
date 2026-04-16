class_name GameTree
extends Node2D

var targeted := false

func set_chop_progress(progress: float) -> void:
	rotation_degrees = progress * 90.0
