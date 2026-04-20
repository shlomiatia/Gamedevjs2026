shader_type canvas_item;

// Maps texture luminosity to a 4-stop warm amber ramp
const vec3 COLOR_DARK  = vec3(0.820, 0.455, 0.255); // #d17441
const vec3 COLOR_MID_D = vec3(0.922, 0.561, 0.282); // #eb8f48
const vec3 COLOR_MID_L = vec3(0.980, 0.753, 0.353); // #fac05a
const vec3 COLOR_LIGHT = vec3(1.000, 0.878, 0.545); // #ffe08b

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	vec3 tint;
	if (lum < 0.333) {
		tint = mix(COLOR_DARK, COLOR_MID_D, lum / 0.333);
	} else if (lum < 0.667) {
		tint = mix(COLOR_MID_D, COLOR_MID_L, (lum - 0.333) / 0.334);
	} else {
		tint = mix(COLOR_MID_L, COLOR_LIGHT, (lum - 0.667) / 0.333);
	}
	COLOR = vec4(tint, col.a);
}
