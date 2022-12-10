shader_type canvas_item;

uniform sampler2D sample;

void fragment() {
/*	float output = noise(UV*TIME*10.0);
	COLOR = vec4(vec3(output),1.0);*/
	vec4 noise = texture(sample, texture(sample, UV).xy + cos(sin(UV*TIME*10.0)*100.0));
	if (noise.r > 0.5) COLOR = vec4(1,1,1,1);
	else COLOR = vec4(0,0,0,1);
}