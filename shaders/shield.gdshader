shader_type spatial;

#include "res://shaders/includes/stretch.gdshaderinc"
#include "res://shaders/includes/rotate.gdshaderinc"

uniform float normal_offset = 0.1;

uniform vec3 stretch_direction = vec3(1.0);
uniform float stretch_scale = 1.0;

//uniform float spin_speed = 1.0;
uniform float rotation = 1.0;

void vertex() {
	//mat3 rotation_matrix = rotation_matrix_y(TIME * spin_speed);
	mat3 rotation_matrix = rotation_matrix_y(rotation);
	mat3 inverted_rotation_matrix = transpose(rotation_matrix);
	
	VERTEX = stretch(VERTEX, rotation_matrix * stretch_direction, stretch_scale);
	VERTEX = inverted_rotation_matrix * VERTEX;
	NORMAL = inverted_rotation_matrix * NORMAL;
	
	VERTEX += NORMAL * normal_offset;
}

uniform float alpha = 1.0;
uniform vec3 color = vec3(1.0, 0.0, 0.0);
uniform vec3 emission = vec3(0.0, 1.0, 0.0);
uniform float emission_strength = 1.0;

void fragment() {
	ALPHA = alpha;
	ALBEDO = color;
	EMISSION = emission * (1.0 - NORMAL.z) * emission_strength;
	
	
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}

void light() {
	DIFFUSE_LIGHT = vec3(0.2);
	SPECULAR_LIGHT = vec3(0.0);
}