extends Node2D

# Variables 
@export var chunk_size: int = 32 # how many blocks per chunk
@export var world_width: int = 20 # in chunks
@export var world_to_pix_scale: int = 8 # How big a block is in pix
@export var world_height: int = 15 # in chunks
@export var world_seed: int = randi() % 100000 # Random seed for the world generation

const GreedyMeshing := preload("res://src/scripts/greedy_meshing.gd")
const Chunk := preload("res://src/world/chunk.tscn")
const TerrainGenerator := preload("res://src/scripts/terrain_generator.gd")

# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var generator = TerrainGenerator.new()
	var terrain_data = generator.generate_noise_terrain(world_seed, world_width, world_height, chunk_size)
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
