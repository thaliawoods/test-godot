shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float distortion : hint_range(0.0, 1.0) = 0.0;
uniform float blur : hint_range(0.0, 1.0) = 0.0;
uniform float saturation : hint_range(0.0, 1.0) = 0.5;
uniform float brightness : hint_range(0.0, 2.0) = 1.0;
uniform float fog_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 fog_color : source_color = vec4(0.75, 0.78, 0.85, 1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	uv += distortion * 0.05 * vec2(sin(uv.y * 30.0 + TIME), cos(uv.x * 30.0 + TIME));
	vec3 col = texture(screen_texture, uv).rgb;
	if (blur > 0.001) {
		vec2 off = blur * 4.0 * SCREEN_PIXEL_SIZE;
		col += texture(screen_texture, uv + vec2(off.x, 0.0)).rgb;
		col += texture(screen_texture, uv - vec2(off.x, 0.0)).rgb;
		col += texture(screen_texture, uv + vec2(0.0, off.y)).rgb;
		col += texture(screen_texture, uv - vec2(0.0, off.y)).rgb;
		col /= 5.0;
	}
	float sat_in = clamp(saturation, 0.0, 1.0);
	float hue_amount = max(0.0, 0.5 - sat_in) * 2.0;
	col = mix(col, col.gbr, hue_amount);
	float sat_boost = 1.0 + max(0.0, sat_in - 0.5) * 6.0;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, sat_boost);
	col *= brightness;
	col = mix(col, fog_color.rgb, fog_amount);
	COLOR = vec4(col, 1.0);
}
