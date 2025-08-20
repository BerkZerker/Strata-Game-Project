extends Node

# TEMP
const dirt_texture: CompressedTexture2D = preload("res://assets/dirt.png")
const grass_texture: CompressedTexture2D = preload("res://assets/grass.png")
const stone_texture: CompressedTexture2D = preload("res://assets/stone.png")

# Do something like this and make 
static var TEXTURE_LOOKUP = {
	0: "res://assets/dirt.png",
	1: "res://assets/grass.png",
	2: "res://assets/stone.png"
}


# Temp sets up the visual mesh, needs to be called after the chunk is added to the scene
# because otherwise the mesh instance will not be ready
func setup_visuals(chunk_instance: Node2D, chunk_size: int) -> void:
	var chunk_data_array = chunk_instance.get_terrain_data()
	var data_texture = _create_data_texture(chunk_data_array, chunk_size)

	var material = chunk_instance.mesh_instance.material
		
	# Set the uniforms for our new shader
	material.set_shader_parameter("chunk_data_texture", data_texture)
	material.set_shader_parameter("dirt_texture", dirt_texture)
	material.set_shader_parameter("grass_texture", grass_texture)
	material.set_shader_parameter("stone_texture", stone_texture)

# maybe TEMP
# Encodes the terrain data into a texture for the shader
# The _create_data_texture helper function remains exactly the same as before.
func _create_data_texture(data_array: Array, size: int) -> ImageTexture:
	# ... same code as the previous answer ...
	var width = size
	var height = size
	var image = Image.create(width, height, false, Image.FORMAT_R8)
	for x in range(width):
		for y in range(height):
			var tile_id = float(data_array[-y - 1][x][0])
			var clump_id = float(data_array[-y - 1][x][1])
			if tile_id != 0:
				image.set_pixel(x, y, Color(clump_id / 255.0, 0, 0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0)) # Transparent

	var texture = ImageTexture.create_from_image(image)
	return texture
