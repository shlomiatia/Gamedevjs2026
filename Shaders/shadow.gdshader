shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(0.0, 0.0, 0.0, a * alpha);
}
