extends Node2D

# Variables 
@export var chunk_size: int = 64 # how many blocks per chunk
@export var world_width: int = 40 # in chunks
@export var world_height: int = 20 # in chunks
@export var world_to_pix_scale: int = 1 # How big a block is in pix
@export var world_seed: int = randi() % 100000 # Random seed for the world generation

const TerrainGenerator := preload("res://src/scripts/terrain_generator.gd")
const TerrainMesher := preload("res://src/scripts/terrain_mesher.gd")

var chunk_data = []
var chunk_meshes = []
var pressed = false
var mouse_button = "none"

# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var generator = TerrainGenerator.new()
	var mesher = TerrainMesher.new()

	chunk_data = generator.generate_noise_terrain(world_seed, Vector2i(world_width, world_height), chunk_size)
	chunk_meshes = mesher.mesh_terrain(chunk_data, world_to_pix_scale, chunk_size)

	# Add the chunks to the scene
	for chunk in chunk_meshes:
		add_child(chunk)


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
			edit_terrain(get_global_mouse_position(), 15, 0) # Add solid blocks
		elif mouse_button == "right":
			edit_terrain(get_global_mouse_position(), 15, 1) # Remove solid blocks


# This function needs to be cleaned up a bit, and should return
# the amount of blocks edited and thier types.
# It will also need to be optimized for performance, as well
# as be able to handle different edit patterns.
func edit_terrain(world_position: Vector2, radius: int, tile_type: int) -> void:
	var center_block_pos = Vector2i(
		floor(world_position.x / world_to_pix_scale),
		floor(world_position.y / world_to_pix_scale)
	)

	var affected_chunks = {} # Using a Dictionary as a Set to store unique chunk positions

	# 1. Determine all blocks to change and update their data
	for x_offset in range(-radius, radius + 1):
		for y_offset in range(-radius, radius + 1):
			var offset = Vector2(x_offset, y_offset)
			if offset.length() <= radius:
				var block_pos = Vector2i(center_block_pos.x + x_offset, center_block_pos.y + y_offset)

				# 2. Convert global block position to chunk and local block positions
				var chunk_pos = Vector2i(floor(float(block_pos.x) / chunk_size), floor(float(block_pos.y) / chunk_size))
				var local_pos = Vector2i(block_pos.x % chunk_size, block_pos.y % chunk_size)

				# Boundary checks for the world
				if chunk_pos.x < 0 or chunk_pos.x >= world_width or chunk_pos.y < 0 or chunk_pos.y >= world_height:
					continue

				# 3. Update the data and mark the chunk as "dirty"
				chunk_data[chunk_pos.x][chunk_pos.y][local_pos.y][local_pos.x] = tile_type
				affected_chunks[chunk_pos] = true

	# 4. Re-mesh all unique chunks that were affected
	var mesher = TerrainMesher.new()
	for chunk_pos in affected_chunks.keys():
		# Find and remove the old chunk mesh (reverse loop)
		for i in range(chunk_meshes.size() - 1, -1, -1):
			var mesh_node = chunk_meshes[i]
			# Compare positions to find the right one
			var expected_pos = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size) * world_to_pix_scale
			if mesh_node.position.is_equal_approx(expected_pos):
				mesh_node.queue_free()
				chunk_meshes.remove_at(i)
				break

		# Create and add the new, updated chunk mesh
		var new_chunk_mesh = mesher.mesh_chunk(chunk_pos, chunk_data[chunk_pos.x][chunk_pos.y], world_to_pix_scale, chunk_size)
		add_child(new_chunk_mesh)
		chunk_meshes.append(new_chunk_mesh)
