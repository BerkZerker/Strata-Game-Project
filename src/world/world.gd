extends Node2D

# Variables
var chunk_size = 16
var world_width = 10
var world_height = 5
var world_to_pix_scale = 32

const GreedyMeshing = preload("res://src/greedy_meshing.gd")
const Chunk = preload("res://src/chunk.tscn")


# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var terrain_data = generate_terrain()
	var chunks = build_terrain(terrain_data)

	# Add the chunks to the scene
	for chunk in chunks:
		add_child(chunk)


# Generates some terrain data based on noise.
func generate_terrain() -> Array:
	# Set up some noise for the terrain generation
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi() % 100000
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
