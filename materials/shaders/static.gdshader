shader_type canvas_item;

uniform sampler2D sample;

void fragment() {
/*	float output = noise(UV*TIME*10.0);
	COLOR = vec4(vec3(output),1.0);*/
	vec4 noise = texture(sample, texture(sample, UV).xy + cos(sin(UV*TIME*10.0)*100.0));
	COLOR = vec4(round(noise.r),round(noise.g),round(noise.r),1);
}