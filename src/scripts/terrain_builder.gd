extends Node

# Right now I'm instanceing `greedy_meshing
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
			# Get the chunk data
			var chunk_data = terrain_data[x][y]
			# Build the chunk
			var chunk = build_chunk(Vector2i(x, y), chunk_data, chunk_size)
			# Add it to the chunks array. This can be indexed with an x & y coordinate pair
			chunks[x].append(chunk)

	return chunks


# Update this function to work in conjunction with the `chunk.gd` file and
# correctly set up the chunk. It should have the collision data, terrain data,
# and visual data (mesh & shader) - I'll probably need to update the `shader_stuff.gd` file
# and make sure the new terrain data format works especially for the greedy messhing .
# Then just clean up the world and player files and the project structure.

# Note that the greedy meshing and the visuals setup will be a single instance, not individual to 
# each chunk.

# Also note that I do need this as a dedicated function since not all chunks will be built at the same time.

# See below comments - this means this whole function can basically be moved into the chunk scene.
# The greedy meshing can be done inside and everything can be encapsulated into a build and rebuild function.
func build_chunk(chunk_pos: Vector2i, chunk_data: Array, chunk_size: int) -> Node:
	# Generate the collision shapes
	var collision_shapes = GreedyMeshing.mesh(chunk_data)

	# Set up a new chunk instance
	var chunk = Chunk.instantiate()
	# Should I do all the setup in a single funciton as `chunk.build(**args)`? YES
	# Do this and then have a function to rebuild the chunk when the `chunk_data` changes

	chunk.add_collision_shapes(collision_shapes)
	chunk.setup_area_2d(chunk_size)

	# Set the chunk's position in the world
	chunk.position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)

	return chunk
