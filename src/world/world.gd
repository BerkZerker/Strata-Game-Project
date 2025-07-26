extends Node2D

# Variables 
@export var chunk_size: int = 32 # how many blocks per chunk
@export var world_width: int = 20 # in chunks
@export var world_to_pix_scale: int = 8 # How big a block is in pix
@export var world_height: int = 15 # in chunks
@export var world_seed: int = randi() % 100000 # Random seed for the world generation

const GreedyMeshing = preload("res://src/scripts/greedy_meshing.gd")
const Chunk = preload("res://src/world/chunk.tscn")

# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var terrain_data = generate_noise_terrain()
	var chunks = build_terrain(terrain_data)

	# Add the chunks to the scene
	for chunk in chunks:
		add_child(chunk)


# Function to build the terrain from the generated data
func build_terrain(terrain_data: Array) -> Array:
	# Get an instance of the GreedyMeshing script
	var mesher = GreedyMeshing.new()
	var chunks = []

	# Loop through the chunks and mesh them
	for x in range(world_width):
		for y in range(world_height):
			var chunk_data = terrain_data[x][y]
			var rectangles = mesher.mesh(chunk_data)
			var collision_shapes = mesher.create_collision_shapes(rectangles, world_to_pix_scale)

			# Set up a new chunk instance
			var chunk = Chunk.instantiate()
			chunk.add_collision_shapes(collision_shapes)
			chunk.setup_area_2d(chunk_size, world_to_pix_scale)

			chunk.position = Vector2(x * chunk_size, y * chunk_size) * world_to_pix_scale
			chunks.append(chunk)

	return chunks


# Generates some terrain data based on noise.
func generate_noise_terrain() -> Array:
	# Set up some noise for the terrain generation
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = world_seed
	noise.frequency = 0.05

	var terrain_data = []

	# Generate the world data
	for x in range(world_width):
		terrain_data.append([]) # Add a new row to the world array
		for y in range(world_height):
			# Generate a chunk of noise data
			var chunk = []

			for i in range(chunk_size):
				chunk.append([])
				for j in range(chunk_size):
					var value = noise.get_noise_2d((x * chunk_size + i), (y * chunk_size + j))
					# Santize the value to be an int - solid is 1 air is 0
					if value > 0:
						value = 1
					else:
						value = 0
					chunk[i].append(value)

			# Add the chunk to the world array
			terrain_data[x].append(chunk)

	return terrain_data


# Generates more realistic terrain with a surface and caves.
func generate_smooth_terrain() -> Array:
	# --- Noise Setup ---
	# Noise for the main surface height (hills and valleys)
	var surface_noise = FastNoiseLite.new()
	surface_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	surface_noise.seed = randi()
	surface_noise.frequency = 0.008 # Low frequency for wide, rolling hills

	# Noise for carving out caves underground
	var cave_noise = FastNoiseLite.new()
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	cave_noise.seed = randi()
	cave_noise.frequency = 0.025 # Higher frequency for more detailed cave shapes

	# --- Terrain Parameters ---
	var surface_level = 50.0 # The average Y level for the ground surface (in tiles)
	var hill_amplitude = 15.0 # How high/low the hills can be
	var cave_density = 1

	# --- Data Structure Initialization ---
	# Pre-initialize the entire world data structure with empty chunks
	var terrain_data = []
	for x in range(world_width):
		terrain_data.append([])
		for y in range(world_height):
			var chunk = []
			for i in range(chunk_size):
				chunk.append(Array())
				chunk[i].resize(chunk_size)
			terrain_data[x].append(chunk)

	# --- Terrain Generation Loop ---
	# Loop through every single tile coordinate in the world
	var world_width_in_tiles = world_width * chunk_size
	var world_height_in_tiles = world_height * chunk_size

	for x in range(world_width_in_tiles):
		# Calculate the surface height at this x-coordinate
		var surface_height = surface_level + (surface_noise.get_noise_1d(x) * hill_amplitude)

		for y in range(world_height_in_tiles):
			var tile_value = 0 # Default to air

			# Check if the current tile is below the ground surface
			if y > surface_height:
				# It's underground, so it's potentially solid.
				# Now, let's use cave noise to decide if we should carve it out.
				var cave_noise_value = cave_noise.get_noise_2d(x, y)

				# If the noise value is below our density threshold, make it solid ground.
				if cave_noise_value < cave_density:
					# NOTE: You could add more logic here for different tile types.
					# For example, check the depth (y) to place stone instead of dirt.
					# if y > surface_height + 15:
					#     tile_value = 2 # Stone
					# else:
					#     tile_value = 1 # Dirt
					tile_value = 1 # For now, all solid ground is type 1
			
			# Determine which chunk this tile belongs to and place the data
			var chunk_x = floori(float(x) / chunk_size)
			var chunk_y = floori(float(y) / chunk_size)
			var tile_in_chunk_x = x % chunk_size
			var tile_in_chunk_y = y % chunk_size

			# Ensure we are not writing outside the allocated world bounds
			if chunk_x < world_width and chunk_y < world_height:
				terrain_data[chunk_x][chunk_y][tile_in_chunk_x][tile_in_chunk_y] = tile_value

	return terrain_data
