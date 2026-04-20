shader_type canvas_item;

const vec3 FROM_0 = vec3(0.969, 0.290, 0.325);
const vec3 FROM_1 = vec3(0.949, 0.184, 0.275);
const vec3 FROM_2 = vec3(0.737, 0.086, 0.259);

uniform vec4 to_color_0 : source_color = vec4(0.969, 0.290, 0.325, 1.0);
uniform vec4 to_color_1 : source_color = vec4(0.949, 0.184, 0.275, 1.0);
uniform vec4 to_color_2 : source_color = vec4(0.737, 0.086, 0.259, 1.0);

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float d0 = distance(col.rgb, FROM_0);
	float d1 = distance(col.rgb, FROM_1);
	float d2 = distance(col.rgb, FROM_2);
	float best = min(d0, min(d1, d2));
	if (best < 0.08) {
		if (d0 <= d1 && d0 <= d2) { COLOR = vec4(to_color_0.rgb, col.a); }
		else if (d1 <= d2) { COLOR = vec4(to_color_1.rgb, col.a); }
		else { COLOR = vec4(to_color_2.rgb, col.a); }
	} else { COLOR = col; }
}
