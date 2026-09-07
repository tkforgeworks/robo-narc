// Taillight states without per-variant art. Two normalized UV rectangles mark
// the lens regions; `intensity` runs from 0 (parked, lights off) through dim
// (driving) to 1 (brake lights). Plain canvas_item shader: runs on WebGL 2.
shader_type canvas_item;

uniform vec4 left_rect = vec4(0.06, 0.60, 0.10, 0.10);
uniform vec4 right_rect = vec4(0.84, 0.60, 0.10, 0.10);
uniform vec4 glow_color : source_color = vec4(1.0, 0.15, 0.10, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float feather : hint_range(0.0, 0.1) = 0.02;

float rect_mask(vec2 uv, vec4 r) {
	vec2 half_size = r.zw * 0.5;
	vec2 center = r.xy + half_size;
	vec2 d = abs(uv - center) - half_size;
	return 1.0 - smoothstep(-feather, feather, max(d.x, d.y));
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float mask = max(rect_mask(UV, left_rect), rect_mask(UV, right_rect));
	float level = clamp(intensity, 0.0, 1.0);
	vec3 off = tex.rgb * 0.7;
	vec3 lit = mix(tex.rgb, glow_color.rgb, 0.85) + glow_color.rgb * 0.5 * level;
	vec3 lens = mix(off, lit, level);
	COLOR = vec4(mix(tex.rgb, lens, mask * tex.a), tex.a);
}
