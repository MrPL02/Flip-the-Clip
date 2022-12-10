shader_type canvas_item;

uniform vec3 divider = vec3(1.0);
uniform float divider_alpha = 3.0;

vec4 limit_color(vec4 input) {
	input.r = round(input.r*divider.r)/divider.r;
	input.b = round(input.b*divider.b)/divider.b;
	input.g = round(input.g*divider.g)/divider.g;
	input.a = round(input.a*divider_alpha)/divider_alpha;
	return input;
}

void fragment() {
/*	vec3 new_color = limit_color(COLOR.rbg);
	COLOR = vec4(new_color.rbg, COLOR.a);*/
	COLOR = limit_color(COLOR);
}