shader_type canvas_item;

uniform sampler2D chunk_data_texture : filter_nearest;
uniform sampler2D dirt_texture : source_color, repeat_enable, filter_nearest;
uniform vec2 dirt_texture_size = vec2(32.0, 32.0);

varying vec2 world_position; // Pixel world pos

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Get tile id from the encoded data in terrain_mesher.gd
	float tile_id = texture(chunk_data_texture, UV).r * 255.0;
	
	if (tile_id < 0.5) {
		// 0 is air
		discard;
	} else if (abs(tile_id - 1.0) < 0.5) {
		// 1 is dirt
		vec2 dirt_uv = world_position / dirt_texture_size;
		COLOR = texture(dirt_texture, dirt_uv);
	} else {
		// fallback if unidentified
		COLOR = vec4(1.0, 0.0, 1.0, 0.0); // Bright magenta 
	}
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
