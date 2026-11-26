shader_type sky;
render_mode use_quarter_res_pass, disable_fog;

uniform vec3 sky_top_color : source_color = vec3(0.11, 0.30, 0.44);
uniform vec3 sky_horizon_color : source_color = vec3(0.95, 0.58, 0.32);
uniform vec3 ground_horizon_color : source_color = vec3(0.16, 0.24, 0.32);
uniform vec3 sun_color : source_color = vec3(1.0, 0.64, 0.34);
uniform vec3 sun_direction = vec3(0.0, 0.22, 0.98);
uniform float night_factor : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_coverage : hint_range(0.0, 1.0) = 0.46;
uniform vec2 cloud_offset = vec2(0.0);
uniform int quality_level = 2;

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

vec3 sky_gradient(vec3 dir) {
	float up = clamp(dir.y, 0.0, 1.0);
	float down = clamp(-dir.y, 0.0, 1.0);
	vec3 above = mix(sky_horizon_color, sky_top_color, pow(up, 0.48));
	return mix(above, ground_horizon_color, down * 0.92);
}

vec4 cloud_layer(vec3 dir) {
	if (dir.y < 0.025) {
		return vec4(0.0);
	}
	vec2 p = dir.xz / (dir.y + 0.14) * 1.25 + cloud_offset;
	float n = 0.5;
	if (quality_level == 0) {
		n = sin(p.x * 1.7 + sin(p.y * 1.3)) * cos(p.y * 1.1) * 0.25 + 0.5;
	} else {
		n = value_noise(p);
		n = mix(n, value_noise(p * 2.07 + vec2(7.3, 2.1)), 0.35);
		if (quality_level > 1) {
			n = mix(n, value_noise(p * 4.13 - vec2(3.8, 5.4)), 0.18);
		}
	}
	float threshold = 1.0 - cloud_coverage;
	float density = smoothstep(threshold, threshold + 0.20, n);
	density *= smoothstep(0.025, 0.16, dir.y);
	float silver = pow(max(dot(dir, normalize(sun_direction)), 0.0), 12.0);
	vec3 shadow_col = mix(vec3(0.20, 0.27, 0.34), vec3(0.025, 0.04, 0.07), night_factor);
	vec3 lit_col = mix(sky_horizon_color * 0.88 + vec3(0.12), sun_color * 0.72 + vec3(0.24), silver * 0.55);
	lit_col *= 1.0 - night_factor * 0.72;
	return vec4(mix(shadow_col, lit_col, 0.46 + silver * 0.54), density * 0.78);
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	if (AT_CUBEMAP_PASS) {
		// Ambient/reflection lighting does not need cloud, star, or sun-disc detail.
		COLOR = sky_gradient(dir);
	} else if (AT_QUARTER_RES_PASS) {
		vec4 clouds = cloud_layer(dir);
		COLOR = clouds.rgb;
		ALPHA = clouds.a;
	} else {
		vec3 base = sky_gradient(dir);
		vec3 sun_dir = normalize(sun_direction);
		float sun_dot = max(dot(dir, sun_dir), 0.0);
		float sun_glow = pow(sun_dot, 48.0) * 0.18 * (1.0 - night_factor);
		float sun_disk = smoothstep(0.99962, 0.99988, sun_dot) * (1.0 - night_factor);
		base += sun_color * (sun_glow + sun_disk * 2.4);
		vec2 star_cell = floor(SKY_COORDS * vec2(520.0, 260.0));
		float star = step(0.9965, hash21(star_cell)) * night_factor;
		star *= smoothstep(0.04, 0.28, dir.y);
		base += vec3(0.72, 0.82, 1.0) * star * 0.72;
		vec4 clouds = QUARTER_RES_COLOR;
		COLOR = mix(base, clouds.rgb, clouds.a);
	}
}
