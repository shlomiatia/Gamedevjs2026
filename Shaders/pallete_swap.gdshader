shader_type canvas_item;

uniform bool is_disabled;
uniform vec4 original_0: source_color;
uniform vec4 original_1: source_color;
uniform vec4 original_2: source_color;
uniform vec4 original_3: source_color;
uniform vec4 original_4: source_color;
uniform vec4 original_5: source_color;
uniform vec4 original_6: source_color;
uniform vec4 original_7: source_color;
uniform vec4 original_8: source_color;
uniform vec4 original_9: source_color;
uniform vec4 original_10: source_color;
uniform vec4 original_11: source_color;
uniform vec4 original_12: source_color;
uniform vec4 replace_0: source_color;
uniform vec4 replace_1: source_color;
uniform vec4 replace_2: source_color;
uniform vec4 replace_3: source_color;
uniform vec4 replace_4: source_color;
uniform vec4 replace_5: source_color;
uniform vec4 replace_6: source_color;
uniform vec4 replace_7: source_color;
uniform vec4 replace_8: source_color;
uniform vec4 replace_9: source_color;
uniform vec4 replace_10: source_color;
uniform vec4 replace_11: source_color;
uniform vec4 replace_12: source_color;
uniform vec4 modulate: source_color = vec4(1, 1, 1, 1);

const float precision = 0.01;

vec4 swap_color(vec4 color){
	vec4 original_colors[13] = vec4[13] (
		original_0, original_1, original_2, original_3, original_4,
		original_5, original_6, original_7, original_8, original_9, original_10, original_11, original_12
	);
	vec4 replace_colors[13] = vec4[13] (
		replace_0, replace_1, replace_2, replace_3, replace_4,
		replace_5, replace_6, replace_7, replace_8, replace_9, replace_10, replace_11, replace_12
	);
	for (int i = 0; i < 13; i ++) {
		if (distance(color, original_colors[i]) <= precision){
            vec3 delta = color.rgb - original_colors[i].rgb;
            vec3 result_rgb = clamp(replace_colors[i].rgb + delta, 0.0, 1.0);
            return vec4(result_rgb, color.a);
		}
	}
	return color;
}


void fragment() {
    if (!is_disabled) {
        vec4 swapped_color = swap_color(texture(TEXTURE, UV));
        COLOR = swapped_color * modulate;
    }
}
