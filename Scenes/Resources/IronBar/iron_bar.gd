class_name IronBar
extends Node2D

const SPACE := 8
const _Shader = preload("res://Shaders/pallete_swap.gdshader")

func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _Shader
	mat.set_shader_parameter("is_disabled", false)
	mat.set_shader_parameter("original_0", Color("ae454a"))
	mat.set_shader_parameter("replace_0", Color("eaeae8"))
	mat.set_shader_parameter("original_1", Color("8c3132"))
	mat.set_shader_parameter("replace_1", Color("cecac9"))
	mat.set_shader_parameter("original_2", Color("542323"))
	mat.set_shader_parameter("replace_2", Color("abafb9"))
	$Sprite2D.material = mat
