extends Node2D

const CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")
const TERRAIN_GENERATOR: Script = preload("uid://bhpl3afoimghh")

var chunks: Array
var chunk_size: int
var world_width: int
var world_height: int
var world_seed: int

func _ready() -> void:
	var generator


# Function to build the terrain from the generated data - returns a 2d array of chunk instances.
func generate_world(terrain_data: Array) -> void:
	# Set up the chunks array and calculate the world size (in chunks)
	var width = terrain_data.size()
	var height = terrain_data[0].size()

	# Loop through the chunks and mesh them
	for x in range(width):
		chunks.append([])
		for y in range(height):
			# Build the chunk using the terrain data and the chunk's position
			var chunk = CHUNK_SCENE.instantiate()
			chunk.generate(terrain_data[x][y], Vector2i(x, y))
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
