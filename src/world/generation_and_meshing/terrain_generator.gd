class_name TerrainGenerator extends Node


# Generates some terrain data based on noise.
static func generate_noise_terrain(world_seed: int, size: Vector2i, chunk_size: int) -> Array:
	# Set up some noise for the terrain generation
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = world_seed
	noise.frequency = 0.003

	var terrain_data = []

	var cell_number = 0

	# Generate the world data
	for x in range(size.x):
		terrain_data.append([]) # Add a new row to the world array
		for y in range(size.y):
			# Generate a chunk of noise data
			var chunk = []

			for i in range(chunk_size):
				chunk.append([])
				for j in range(chunk_size):
					var value = noise.get_noise_2d(float(x * chunk_size + j), float(y * chunk_size + i))
					# Santize the value to be an int - solid is 1 air is 0
					if value > 0.3:
						value = 3 # Stone
					elif value > 0.15:
						value = 1 # Dirt
					elif value > 0.1:
						value = 2 # Grass
					else:
						value = 0
					chunk[i].append([value, cell_number]) # DEBUG TEMP

			# Add the chunk to the world array
			terrain_data[x].append(chunk)
		
		# Increment the clump number for the next clump (DEBUG)
		cell_number += 1
		
	return terrain_data
