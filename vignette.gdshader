shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 center = uv - 0.5;
	float dist = length(center);

	float vignette = smoothstep(0.25, 0.9, dist);
	vec4 base = texture(SCREEN_TEXTURE, uv);
	vec4 dark = vec4(0.0, 0.0, 0.0, 1.0);
	COLOR = mix(base, dark, vignette * intensity);
}