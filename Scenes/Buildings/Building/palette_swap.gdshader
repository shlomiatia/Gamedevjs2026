shader_type canvas_item;

const vec3 FROM_0 = vec3(0.537255, 0.623529, 0.400000); // #899f66
const vec3 FROM_1 = vec3(0.380392, 0.521569, 0.352941); // #61855a
const vec3 FROM_2 = vec3(0.298039, 0.376471, 0.317647); // #4c6051

uniform vec4 to_color_0 : source_color = vec4(0.537255, 0.623529, 0.400000, 1.0);
uniform vec4 to_color_1 : source_color = vec4(0.380392, 0.521569, 0.352941, 1.0);
uniform vec4 to_color_2 : source_color = vec4(0.298039, 0.376471, 0.317647, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float d0 = distance(col.rgb, FROM_0);
	float d1 = distance(col.rgb, FROM_1);
	float d2 = distance(col.rgb, FROM_2);
	float best = min(d0, min(d1, d2));
	if (best < 0.08) {
		if (d0 <= d1 && d0 <= d2) {
			COLOR = vec4(to_color_0.rgb, col.a);
		} else if (d1 <= d2) {
			COLOR = vec4(to_color_1.rgb, col.a);
		} else {
			COLOR = vec4(to_color_2.rgb, col.a);
		}
	} else {
		COLOR = col;
	}
}
