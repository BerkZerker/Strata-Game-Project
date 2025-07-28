extends Node

const GreedyMeshing := preload("res://src/scripts/greedy_meshing.gd")
const Chunk := preload("res://src/world/chunk.tscn")


# Function to build the terrain from the generated data
func mesh_terrain(terrain_data: Array, world_to_pix_scale: int, chunk_size: int) -> Array:
	# Set up the chunks array and calculate the world size (in chunks)
	var chunks = []

	var height = terrain_data.size()
	if height == 0:
		return []
	var width = terrain_data[0].size()
	if width == 0:
		return []
		
	print(width, height)
    # Throwing an error here. Fix!

	# Loop through the chunks and mesh them
	for x in range(width):
		for y in range(height):
			var chunk_data = terrain_data[x][y]
			var chunk = mesh_chunk(Vector2i(x, y), chunk_data, world_to_pix_scale, chunk_size)
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
