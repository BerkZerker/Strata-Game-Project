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


func _on_player_chunk_changed(new_player_pos: Vector2i) -> void:
	# Calculate the bounds of chunks that should be loaded
	var min_x = new_player_pos.x - GlobalSettings.LOAD_RADIUS
	var max_x = new_player_pos.x + GlobalSettings.LOAD_RADIUS
	var min_y = new_player_pos.y - GlobalSettings.LOAD_RADIUS
	var max_y = new_player_pos.y + GlobalSettings.LOAD_RADIUS

	
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

	# Calculate the bounds to enable collision shapes
	var collision_min_x = new_player_pos.x - GlobalSettings.COLLISION_RADIUS
	var collision_max_x = new_player_pos.x + GlobalSettings.COLLISION_RADIUS
	var collision_min_y = new_player_pos.y - GlobalSettings.COLLISION_RADIUS
	var collision_max_y = new_player_pos.y + GlobalSettings.COLLISION_RADIUS

	# Generate new chunks within radius
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2i(x, y)

			# Check if chunk doesn't exist and create it
			if not chunks.has(pos):
				# Generate new chunk
				var chunk_data = terrain_generator.generate_chunk(pos)
				var chunk_scene = load("uid://dbbq2vtjx0w0y")
				var new_chunk = chunk_scene.instantiate()
				new_chunk.generate(chunk_data, pos)
				new_chunk.build()
				chunks[pos] = new_chunk
				add_child(new_chunk)

			# Enable or disable collision based on distance to player
			if pos.x >= collision_min_x and pos.x <= collision_max_x and pos.y >= collision_min_y and pos.y <= collision_max_y:
				chunks[pos].enable_collision()
			else:
				chunks[pos].disable_collision()
