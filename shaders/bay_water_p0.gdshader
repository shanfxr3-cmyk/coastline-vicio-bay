shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.06, 0.55, 0.62);
uniform vec3 deep_color : source_color = vec3(0.02, 0.18, 0.30);
uniform vec3 sky_reflect_color : source_color = vec3(0.56, 0.68, 0.76);
uniform float wave_speed = 0.45;
uniform float wave_scale = 0.20;
uniform float roughness_base = 0.07;
uniform int quality_level = 2;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (quality_level == 0) {
		VERTEX.y += sin(world_pos.x * 0.16 + TIME) * 0.08;
	} else {
		float w1 = sin(world_pos.x * 0.22 + TIME * 1.4) * cos(world_pos.z * 0.19 + TIME * 1.1);
		float w2 = sin((world_pos.x + world_pos.z) * 0.37 - TIME * 1.9);
		VERTEX.y += (w1 * 0.12 + w2 * 0.05);
	}
}

void fragment() {
	vec2 uv_a = world_pos.xz * wave_scale + vec2(TIME * wave_speed * 0.08, TIME * wave_speed * 0.05);
	float h_x = cos(uv_a.x * 6.2831) * 0.55;
	float h_z = sin(uv_a.y * 6.2831) * 0.55;
	if (quality_level > 0) {
		vec2 uv_b = world_pos.xz * (wave_scale * 1.7) - vec2(TIME * wave_speed * 0.06, TIME * wave_speed * 0.09);
		h_x += cos(uv_b.x * 6.2831) * 0.35;
		h_z += sin(uv_b.y * 6.2831) * 0.35;
	}
	vec3 wave_n_world = normalize(vec3(-h_x * 0.18, 1.0, -h_z * 0.18));
	vec3 wave_n_view = normalize((VIEW_MATRIX * vec4(wave_n_world, 0.0)).xyz);

	NORMAL = wave_n_view;
	float fresnel = 1.0 - clamp(dot(normalize(VIEW), wave_n_view), 0.0, 1.0);
	fresnel = fresnel * fresnel * fresnel;
	float shore_mix = clamp((world_pos.z - 10.0) / 65.0, 0.0, 1.0);
	vec3 water_col = mix(shallow_color, deep_color, shore_mix);

	ALBEDO = mix(water_col, sky_reflect_color, fresnel * 0.58);
	METALLIC = 0.08;
	SPECULAR = 0.88;
	ROUGHNESS = mix(roughness_base, 0.025, fresnel);
}
