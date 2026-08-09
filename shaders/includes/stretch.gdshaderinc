vec3 stretch(vec3 vertex, vec3 stretch_direction, float stretch_scale) {
	vec3 projection = dot(vertex, stretch_direction) * stretch_direction;
	vec3 parallel = vertex - projection;
	return parallel * (1.0 / sqrt(stretch_scale)) + projection * stretch_scale;
}

//void vertex() {
	//VERTEX = stretch(VERTEX);
//}