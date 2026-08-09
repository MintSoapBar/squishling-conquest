mat3 rotation_matrix_x(float theta) {
	float cosa = cos(theta);
	float sina = sin(theta);
	
	mat3 rotate_x  = mat3(
	   vec3(1.0, 0.0, 0.0),
	   vec3(0.0, cosa, -sina),
	   vec3(0.0, sina, cosa)
	);
	
	return rotate_x;
}

mat3 rotation_matrix_y(float theta) {
	float cosa = cos(theta);
	float sina = sin(theta);
	
	mat3 rotate_y  = mat3(
	   vec3(cosa, 0.0, sina),
	   vec3(0.0, 1.0, 0.0),
	   vec3(-sina, 0.0, cosa)
	);
	
	return rotate_y;
}


mat3 rotation_matrix_z(float theta) {
	float cosa = cos(theta);
	float sina = sin(theta);
	
	mat3 rotate_z  = mat3(
	   vec3(cosa,-sina, 0.0),
	   vec3(sina, cosa, 0.0),
	   vec3(0.0, 0.0, 1.0)
	);
	
	return rotate_z;
}


vec3 rotate_y(vec3 v, float cosine, float sine) {
    return vec3(
        cosine * v.x + sine * v.z,
        v.y,
        -sine * v.x + cosine * v.z
    );
}


//void vertex() {
	//mat3 rotation_matrix = (
		//rotation_matrix_x(1.0) 
		//* rotation_matrix_y(1.0) 
		//* rotation_matrix_z(1.0)
	//);
	//vec3 rotated_vertex = rotation_matrix * VERTEX;
	//vec3 rotated_normals = rotation_matrix * NORMAL;
//
	//VERTEX =  rotated_vertex;
	//NORMAL =  rotated_normals;
//}