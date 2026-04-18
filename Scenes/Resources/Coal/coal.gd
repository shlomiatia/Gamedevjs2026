class_name Coal
extends Node2D

const SPACE := 8
const _Shader = preload("res://Shaders/pallete_swap.gdshader")

func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _Shader
	mat.set_shader_parameter("is_disabled", false)
	mat.set_shader_parameter("original_0", Color("ae454a"))
	mat.set_shader_parameter("replace_0", Color("28192f"))
	mat.set_shader_parameter("original_1", Color("8c3132"))
	mat.set_shader_parameter("replace_1", Color("140d18"))
	mat.set_shader_parameter("original_2", Color("542323"))
	mat.set_shader_parameter("replace_2", Color("000000"))
	$Sprite2D.material = mat
