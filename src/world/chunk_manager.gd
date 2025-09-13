class_name ChunkManager extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation

var chunks: Dictionary
var terrain_generator: TerrainGenerator


# Setup the chunk manager
func _ready() -> void:
	chunks = {}
	terrain_generator = TerrainGenerator.new(WORLD_SEED)

	# Connect to player chunk changed signal
	SignalBus.player_chunk_changed.connect(_on_player_chunk_changed)


func _on_player_chunk_changed(new_chunk_pos: Vector2i) -> void:
	# Calculate the bounds of chunks that should be loaded
	var min_x = new_chunk_pos.x - GlobalSettings.LOD_RADIUS
	var max_x = new_chunk_pos.x + GlobalSettings.LOD_RADIUS
	var min_y = new_chunk_pos.y - GlobalSettings.LOD_RADIUS
	var max_y = new_chunk_pos.y + GlobalSettings.LOD_RADIUS
	
	# First, unload chunks that are too far away
	var chunks_to_remove = []
	for chunk_pos in chunks:
		if chunk_pos.x < min_x or chunk_pos.x > max_x or chunk_pos.y < min_y or chunk_pos.y > max_y:
			# Queue chunk for removal
			chunks_to_remove.append(chunk_pos)
	
	# Remove the chunks outside radius
	for chunk_pos in chunks_to_remove:
		chunks[chunk_pos].queue_free()
		chunks.erase(chunk_pos)

	# Generate new chunks within radius
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2i(x, y)
			
			# Skip if chunk already exists
			if chunks.has(pos):
				continue
			else:
				# Generate new chunk
				var chunk_data = terrain_generator.generate_chunk(pos)
				var new_chunk = Chunk.new(chunk_data, pos)
				# Handle enabling/disabling based on distance if needed here
				
				# Add to chunks dictionary and scene tree
				chunks[pos] = new_chunk
				add_child(new_chunk)

	
# # Helper function to convert Vector2i to string key
# func vec2i_to_str(vec: Vector2i) -> String:
# 	return "%d,%d" % [vec.x, vec.y]


# # Helper function to convert string key back to Vector2i
# func str_to_vec2i(pos_str: String) -> Vector2i:
# 	var parts = pos_str.split(",")
# 	return Vector2i(int(parts[0]), int(parts[1]))


# Function to build the terrain from the generated data - returns a 2d array of chunk instances.
# func generate_world() -> void:
# 	# Set up the generator
# 	terrain_generator = TerrainGenerator.new(world_seed)
# 	# Set up the chunks array and calculate the world size (in chunks)
# 	var width = terrain_data.size()
# 	var height = terrain_data[0].size()
# 	# Loop through the chunks and mesh them
# 	for x in range(width):
# 		chunks.append([])
# 		for y in range(height):
# 			# Build the chunk using the terrain data and the chunk's position
# 			var chunk = Chunk.new(terrain_data[x][y], Vector2i(x, y))
# 			# Add it to the chunks array. This can be indexed with an x & y coordinate pair
# 			chunks[x].append(chunk)
# 	# Add the chunks to the scene
# 	for x in range(width):
# 		for y in range(height):
# 			add_child(chunks[x][y])
# 	# build the chunks
# 	build_chunks()
# func build_chunks() -> void:
# 	for x in range(chunks.size()):
# 		for y in range(chunks[x].size()):
# 			chunks[x][y].build()
# func generate_chunk() -> generates the chunk data and sets up a new chunk scene
# func build_chunk() -> sets up the collision shapes and visual mesh
# func rebuild_chunk() -> rebuilds the chunk's visual mesh and collision shapes
