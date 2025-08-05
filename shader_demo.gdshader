shader_type canvas_item;

uniform float blue = 1.0;

void vertex() {
	VERTEX += vec2(10.0, 0.0);
}

void fragment() {
	//COLOR = vec4(UV, 0.5, 1.0);
	COLOR = texture(TEXTURE, UV);
	COLOR.b = blue;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
