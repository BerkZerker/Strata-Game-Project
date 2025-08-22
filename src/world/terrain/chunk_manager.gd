extends Node2D


# Function to build the terrain from the generated data - returns a 2d array of chunk instances.
func build_terrain(terrain_data: Array) -> Array:
	# Set up the chunks array and calculate the world size (in chunks)
	var chunks = []
	var width = terrain_data.size()
	var height = terrain_data[0].size()
	# Load the chunk scene
	var chunk_scene = load("res://src/world/terrain/chunk.tscn")

	# Loop through the chunks and mesh them
	for x in range(width):
		chunks.append([])
		for y in range(height):
			# Build the chunk using the terrain data and the chunk's position
			var chunk = chunk_scene.instantiate()
			chunk.setup(terrain_data[x][y], Vector2i(x, y))
			# Add it to the chunks array. This can be indexed with an x & y coordinate pair
			chunks[x].append(chunk)

	return chunks
