// stone_bevel_FIXED.gdshader
shader_type canvas_item;

uniform sampler2D id_texture;
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 1.0, 0.2);
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    
    // --- FIX IS HERE ---
    // Use the built-in uniform for the main texture's pixel size.
    vec2 pixel_size = TEXTURE_PIXEL_SIZE; 
    
    float my_id = texture(id_texture, UV).r;
    
    // Neighbors
    float id_up = texture(id_texture, UV + vec2(0.0, -pixel_size.y)).r;
    float id_left = texture(id_texture, UV + vec2(-pixel_size.x, 0.0)).r;
    float id_down = texture(id_texture, UV + vec2(0.0, pixel_size.y)).r;
    float id_right = texture(id_texture, UV + vec2(pixel_size.x, 0.0)).r;

    // The rest of the logic is the same...
    if (abs(my_id - id_up) > 0.001 || abs(my_id - id_left) > 0.001) {
        base_color.rgb = mix(base_color.rgb, shadow_color.rgb, shadow_color.a);
    } 
    else if (abs(my_id - id_down) > 0.001 || abs(my_id - id_right) > 0.001) {
        base_color.rgb = mix(base_color.rgb, highlight_color.rgb, highlight_color.a);
    }
    
    COLOR = base_color;
}