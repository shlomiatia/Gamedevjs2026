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
