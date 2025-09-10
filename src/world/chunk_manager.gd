class_name ChunkManager extends Node2D


# Variables  MOVED HERE FROM WORLD
@export var CHUNK_SIZE: int = 64 # how tiles wide and tall a chunk is
@export var LOD_DISTANCE: int = 10 # in chunks
@export var WORLD_SEED: int = randi() % 100000 # Random seed for the world generation

var chunks: Array
var chunk_size: int
var load_distance: int
var world_seed: int
var terrain_generator: TerrainGenerator


# Function to build the terrain from the generated data - returns a 2d array of chunk instances.
func generate_world() -> void:
	# Set up the generator
	terrain_generator = TerrainGenerator.new(world_seed)

	# Set up the chunks array and calculate the world size (in chunks)
	var width = terrain_data.size()
	var height = terrain_data[0].size()

	# Loop through the chunks and mesh them
	for x in range(width):
		chunks.append([])
		for y in range(height):
			# Build the chunk using the terrain data and the chunk's position
			var chunk = Chunk.new(terrain_data[x][y], Vector2i(x, y))
			# Add it to the chunks array. This can be indexed with an x & y coordinate pair
			chunks[x].append(chunk)

	
	# Add the chunks to the scene
	for x in range(width):
		for y in range(height):
			add_child(chunks[x][y])

	# build the chunks
	build_chunks()


func build_chunks() -> void:
	for x in range(chunks.size()):
		for y in range(chunks[x].size()):
			chunks[x][y].build()


# func generate_chunk() -> generates the chunk data and sets up a new chunk scene
# func build_chunk() -> sets up the collision shapes and visual mesh
# func rebuild_chunk() -> rebuilds the chunk's visual mesh and collision shapes
