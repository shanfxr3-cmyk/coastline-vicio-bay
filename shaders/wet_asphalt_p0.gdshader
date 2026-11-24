shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec3 dry_albedo : source_color = vec3(0.11, 0.12, 0.14);
uniform vec3 wet_albedo : source_color = vec3(0.045, 0.052, 0.065);
uniform float wetness : hint_range(0.0, 1.0) = 0.65;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float macro = value_noise(world_pos.xz * 0.14);
	float micro = value_noise(world_pos.xz * 4.5);
	float puddle_mask = smoothstep(0.46, 0.72, macro) * wetness;

	vec3 col = mix(dry_albedo, wet_albedo, puddle_mask);
	col *= mix(0.92, 1.08, micro);

	ALBEDO = col;
	METALLIC = 0.04;
	SPECULAR = mix(0.5, 0.9, puddle_mask);
	ROUGHNESS = mix(0.76, 0.08, puddle_mask);
}
