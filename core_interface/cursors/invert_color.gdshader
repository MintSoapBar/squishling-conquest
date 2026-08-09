shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

void fragment(){
    vec3 world_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0).rgb;
	
	// furthest black/white from screen color
	//float avg = (world_color.x + world_color.y + world_color.z) / 3.0;
    //COLOR = vec4(vec3(1.0 - round(avg)), 1.0);
	
	// invert screen color
	COLOR = vec4(1.0 - world_color, 1.0);
}
