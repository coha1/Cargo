shader_type spatial;
render_mode cull_disabled;

uniform float grid_size : hint_range(1.0, 100.0) = 10.0;
uniform vec4 base_color : source_color = vec4(0.70, 0.64, 0.50, 1.0);
uniform vec4 line_color : source_color = vec4(0.38, 0.32, 0.22, 1.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_pos.xz / grid_size;
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = min(grid.x, grid.y);
	float is_line = 1.0 - clamp(line, 0.0, 1.0);
	ALBEDO = mix(base_color.rgb, line_color.rgb, is_line);
	ROUGHNESS = 0.95;
}
