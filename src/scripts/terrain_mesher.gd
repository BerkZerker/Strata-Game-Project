extends Node

const GreedyMeshing: Script = preload("res://src/scripts/greedy_meshing.gd")
const Chunk: PackedScene = preload("res://src/world/chunk.tscn")


# TEMP
const dirt_texture: CompressedTexture2D = preload("res://assets/mc-dirt.png")


# Function to build the terrain from the generated data
func mesh_terrain(terrain_data: Array, world_to_pix_scale: int, chunk_size: int) -> Array:
	# Set up the chunks array and calculate the world size (in chunks)
	var chunks = []

	var height = terrain_data[0].size()
	if height == 0:
		return []
	var width = terrain_data.size()
	if width == 0:
		return []
		
	# Loop through the chunks and mesh them
	for x in range(width):
		for y in range(height):
			var chunk_data = terrain_data[x][y]
			var chunk = mesh_chunk(Vector2i(x, y), chunk_data, world_to_pix_scale, chunk_size)
			chunk.set_terrain_data(chunk_data)
			chunks.append(chunk)

	return chunks


# Meshes the provided chunk
func mesh_chunk(chunk_pos: Vector2i, chunk_data: Array, world_to_pix_scale: int, chunk_size: int) -> Node:
	# Generate the collision mesh
	var mesher = GreedyMeshing.new()
	var rectangles = mesher.mesh(chunk_data)
	var collision_shapes = mesher.create_collision_shapes(rectangles, world_to_pix_scale)

	# Set up a new chunk instance
	var chunk = Chunk.instantiate()
	chunk.add_collision_shapes(collision_shapes)
	chunk.setup_area_2d(chunk_size, world_to_pix_scale)

	# Set the chunk's position in the world
	chunk.position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size) * world_to_pix_scale

	return chunk


# Temp sets up the visual mesh, needs to be called after the chunk is added to the scene
# because otherwise the mesh instance will not be ready
func setup_visuals(chunk_instance: Node2D, chunk_size: int) -> void:
	var chunk_data_array = chunk_instance.get_terrain_data()
	var data_texture = _create_data_texture(chunk_data_array, chunk_size)

	var material = chunk_instance.mesh_instance.material
	if not material is ShaderMaterial:
		print("Chunk material is not a ShaderMaterial!")
		return
		
	# Set the uniforms for our new shader
	material.set_shader_parameter("chunk_data_texture", data_texture)
	material.set_shader_parameter("dirt_texture", dirt_texture)


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
			var tile_id = float(data_array[-y - 1][x])
			if tile_id != 0:
				image.set_pixel(x, y, Color(tile_id / 255.0, 0, 0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0)) # Transparent

	var texture = ImageTexture.create_from_image(image)
	return texture
