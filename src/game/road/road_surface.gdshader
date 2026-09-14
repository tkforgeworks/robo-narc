shader_type canvas_item;
// Perspective-correct texturing for a road-space quad drawn with draw_polygon.
// Each vertex colour carries (u * f, v * f, f) with f the perspective factor at
// that depth; interpolating those linearly in screen space and dividing back
// recovers the true texture coordinate across the whole quad.

uniform float opacity : hint_range(0.0, 1.0) = 1.0;

varying vec3 projected_uv;

void vertex() {
	projected_uv = COLOR.rgb;
	COLOR = vec4(1.0);
}

void fragment() {
	vec2 uv = projected_uv.xy / max(projected_uv.z, 0.00001);
	COLOR = texture(TEXTURE, uv) * vec4(1.0, 1.0, 1.0, opacity);
}
