shader_type spatial;
render_mode depth_draw_always;

uniform float normal_offset = 0.0;

uniform float time = 0.0;

uniform float wobble_strength = 0.01;
uniform float wobble_speed = 5.0;

uniform float wobble_y_multiplier = 1.0;
uniform float wobble_x_multiplier = 0.0;
uniform float wobble_z_multiplier = 0.0;

uniform vec3 stretch_direction = vec3(1.0);
uniform float stretch_scale = 1.0;

vec3 stretch(vec3 vertex) {
	vec3 projection = dot(vertex, stretch_direction) * stretch_direction;
	vec3 parallel = vertex - projection;
	return parallel * (1.0 / sqrt(stretch_scale)) + projection * stretch_scale;
}

void vertex() {
	//float time = TIME;
	
	VERTEX = stretch(VERTEX);
	
	float noise = sin(VERTEX.y * wobble_y_multiplier 
		+ VERTEX.x * wobble_x_multiplier 
		+ VERTEX.z * wobble_z_multiplier 
		+ time * wobble_speed) * wobble_strength;
	
	VERTEX += normalize(VERTEX) * noise + NORMAL * normal_offset;
}

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;

uniform float alpha = 1.0;

uniform vec3 add_color = vec3(0.0, 0.0, 0.0);
uniform vec3 multiply_color = vec3(0.0, 0.5, 0.0);
uniform vec3 emission_color = vec3(0.0, 1.0, 0.0);
uniform float ripple_strength = 0.008;
uniform float ripple_speed_x = 2.0;
uniform float ripple_speed_y = 2.7;
uniform float zoom_strength = 0.04;
uniform float emission_strength = 0.5;

void fragment() {
	//float time = TIME;
	
	vec2 zoom_uv = -vec2(NORMAL.x, NORMAL.y) * zoom_strength;
	zoom_uv.y += sin(SCREEN_UV.x * 60.0 + ripple_speed_y * time) * ripple_strength;
	zoom_uv.x += sin(SCREEN_UV.y * 10.0 + ripple_speed_x * time) * ripple_strength;
	
	vec2 distorted_uv = SCREEN_UV;
	distorted_uv += zoom_uv;
	vec3 screen_color = texture(screen_tex, distorted_uv).rgb;
	
	ALPHA = alpha;
	ALBEDO = add_color + screen_color * multiply_color;
	//ALBEDO = mix(ALBEDO, glancing_color, 1.0 - NORMAL.z);
	//EMISSION = mix(vec3(0.0), emission_color, emission_strength * pow(1.0 - NORMAL.z, 2.0));
	EMISSION = mix(vec3(0.0), emission_color, emission_strength * pow(1.0 - dot(NORMAL, VIEW), 2));
	
	//ROUGHNESS = 1.0;
	//METALLIC = -0.0;
}

//void light() {
	//DIFFUSE_LIGHT = vec3(1.0);
	//SPECULAR_LIGHT = vec3(0.0);
//}