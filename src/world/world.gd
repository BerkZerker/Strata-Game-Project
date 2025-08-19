extends Node2D

# Variables 
@export var CHUNK_SIZE: int = 64 # how many blocks per chunk
@export var WORLD_WIDTH: int = 20 # in chunks
@export var WORLD_HEIGHT: int = 20 # in chunks
@export var WORLD_SEED: int = randi() % 100000 # Random seed for the world generation

const TerrainGenerator: Script = preload("res://src/scripts/terrain_generator.gd")
const TerrainBuilder: Script = preload("res://src/scripts/terrain_builder.gd")

var chunk_data = []
var chunk_meshes = []
var pressed = false
var mouse_button = "none"

# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var generator = TerrainGenerator.new()
	var builder = TerrainBuilder.new()

	var world_data = generator.generate_noise_terrain(WORLD_SEED, Vector2i(WORLD_WIDTH, WORLD_HEIGHT), CHUNK_SIZE)
	var chunks = builder.build_terrain(world_data, CHUNK_SIZE)

	# Add the chunks to the scene
	for x in range(WORLD_WIDTH):
		for y in range(WORLD_HEIGHT):
			add_child(chunks[x][y])

		# TEMP
		# Visuals should be set up when the chunk is BUILT
		#mesher.setup_visuals(chunk, chunk_size, world_to_pix_scale)


# ALl of this is highly sketch

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_button = "left"
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_button = "right"

	elif event is InputEventMouseButton and not event.pressed:
		pressed = false
		mouse_button = "none"
	
	if event is InputEventMouseButton or InputEventMouseMotion and pressed:
		if mouse_button == "left":
			edit_terrain(get_global_mouse_position(), 10, 0) # Add solid blocks
		elif mouse_button == "right":
			edit_terrain(get_global_mouse_position(), 10, 3) # Remove solid blocks


# This function needs to be cleaned up a bit, and should return
# the amount of blocks edited and thier types.
# It will also need to be optimized for performance, as well
# as be able to handle different edit patterns.
func edit_terrain(world_position: Vector2, radius: int, tile_type: int) -> void:
	var center_block_pos = Vector2i(
		floor(world_position.x),
		floor(world_position.y)
	)

	var affected_chunks = {} # Using a Dictionary as a Set to store unique chunk positions

	# 1. Determine all blocks to change and update their data
	for x_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			var offset = Vector2(x_offset, y_offset)
			if offset.length() <= radius:
				var block_pos = Vector2i(center_block_pos.x + x_offset, center_block_pos.y + y_offset)

				# 2. Convert global block position to chunk and local block positions
				var chunk_pos = Vector2i(floor(float(block_pos.x) / CHUNK_SIZE), floor(float(block_pos.y) / CHUNK_SIZE))
				var local_pos = Vector2i(block_pos.x % CHUNK_SIZE, block_pos.y % CHUNK_SIZE)

				# Boundary checks for the world
				if chunk_pos.x < 0 or chunk_pos.x >= WORLD_WIDTH or chunk_pos.y < 0 or chunk_pos.y >= WORLD_HEIGHT:
					continue

				# 3. Update the data and mark the chunk as "dirty"
				chunk_data[chunk_pos.x][chunk_pos.y][local_pos.y][local_pos.x] = [tile_type, 0] # SUPER TEMP
				affected_chunks[chunk_pos] = true

	# 4. Re-mesh all unique chunks that were affected
	var builder = TerrainBuilder.new()
	for chunk_pos in affected_chunks.keys():
		# Find and remove the old chunk mesh (reverse loop)
		for i in range(chunk_meshes.size() - 1, -1, -1):
			var mesh_node = chunk_meshes[i]
			# Compare positions to find the right one
			var expected_pos = Vector2(chunk_pos.x * CHUNK_SIZE, chunk_pos.y * CHUNK_SIZE)
			if mesh_node.position.is_equal_approx(expected_pos):
				mesh_node.queue_free()
				chunk_meshes.remove_at(i)
				break

		# Create and add the new, updated chunk mesh
		var new_chunk_mesh = builder.build_chunk(chunk_pos, chunk_data[chunk_pos.x][chunk_pos.y], CHUNK_SIZE)
		# TEMP
		new_chunk_mesh.set_terrain_data(chunk_data[chunk_pos.x][chunk_pos.y])
		add_child(new_chunk_mesh)
		# TEMP
		builder.setup_visuals(new_chunk_mesh, CHUNK_SIZE)
		
		chunk_meshes.append(new_chunk_mesh)
