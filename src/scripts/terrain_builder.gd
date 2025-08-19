extends Node

# Right now I'm instanceing this locally but it should be passed down.
const GreedyMeshing: Script = preload("res://src/scripts/greedy_meshing.gd")
const Chunk: PackedScene = preload("res://src/world/chunk.tscn")


# Function to build the terrain from the generated data - returns a 2d array of chunk instances.
func build_terrain(terrain_data: Array, chunk_size: int) -> Array:
	# Set up the chunks array and calculate the world size (in chunks)
	var chunks = []

	# Get the width and height of the terrain data
	var width = terrain_data.size()
	if width == 0:
		return []
	var height = terrain_data[0].size()
	if height == 0:
		return []
		
	# Loop through the chunks and mesh them
	for x in range(width):
		chunks.append([])
		for y in range(height):
			var chunk_data = terrain_data[x][y]

			var chunk = build_chunk(Vector2i(x, y), chunk_data, chunk_size)

			chunk.set_terrain_data(chunk_data)
			chunks[x].append(chunk)

	return chunks


# Update this function to work in conjunction with the `chunk.gd` file and
# correctly set up the chunk. It should have the collision data, terrain data,
# and visual data (mesh & shader) - I'll probably need to update the `shader_stuff.gd` file
# and make sure the new terrain data format works especially for the greedy messhing .
# Then just clean up the world and player files and the project structure.

# Note that the greedy meshing and the visuals setup will be a single instance, not individual to 
# each chunk.
func build_chunk(chunk_pos: Vector2i, chunk_data: Array, chunk_size: int) -> Node:
	# Generate the collision mesh
	var mesher = GreedyMeshing.new()
	var collision_shapes = mesher.mesh(chunk_data)

	# Set up a new chunk instance
	var chunk = Chunk.instantiate()
	chunk.add_collision_shapes(collision_shapes)
	chunk.setup_area_2d(chunk_size, world_to_pix_scale)

	# Set the chunk's position in the world
	chunk.position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size) * world_to_pix_scale

	return chunk
