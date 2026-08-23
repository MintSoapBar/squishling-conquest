shader_type spatial;

uniform sampler2D base_texture : source_color, filter_nearest;
uniform vec4 base_tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform sampler2D tint_texture : source_color, filter_nearest;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec4 lerp(vec4 a, vec4 b, float delta) {
	return a + (b-a) * delta;
}

void fragment() {
	vec4 base_color = texture(base_texture, world_position.xz);
	vec4 tint_color = texture(tint_texture, UV);
	if (tint_color.a < 1.0) {
		tint_color = lerp(base_tint_color, vec4(tint_color.rgb, 1.0), tint_color.a);
	}
	
	vec4 final_color = base_color * tint_color;
	
	ALBEDO = final_color.rgb;
}