class_name ChunkManager extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation

var chunks: Dictionary = {}

var _terrain_generator: TerrainGenerator
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore

var _generation_queue: Array[Vector2i] = []
var _removal_queue: Array[Vector2i] = []


# Setup the chunk manager
func _ready() -> void:
	_terrain_generator = TerrainGenerator.new(WORLD_SEED)

	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_process_chunk_updates)

	# Connect to player chunk changed signal
	SignalBus.player_chunk_changed.connect(_on_player_chunk_changed)


func _process_chunk_updates() -> void:
	while true:
		_semaphore.wait()
		_mutex.lock()
		# Process chunk updates here if needed
		# Do all looping over the queues and updates to the arrays inside the mutex lock

		for pos in _removal_queue:
			if chunks.has(pos):
				chunks[pos].call_deferred("queue_free")
				chunks.erase(pos)
		_removal_queue.clear()

		for pos in _generation_queue:
			var chunk_data = _terrain_generator.generate_chunk(pos)
			var chunk_scene = load("uid://dbbq2vtjx0w0y")
			var new_chunk = chunk_scene.instantiate()
			new_chunk.generate(chunk_data, pos)
			new_chunk.build()
			chunks[pos] = new_chunk
			call_deferred("add_child", new_chunk)
		_generation_queue.clear()

		_mutex.unlock()
		

func _on_player_chunk_changed(new_player_pos: Vector2i) -> void:
	# Calculate the bounds of chunks that should be loaded
	var min_x = new_player_pos.x - GlobalSettings.LOAD_RADIUS
	var max_x = new_player_pos.x + GlobalSettings.LOAD_RADIUS
	var min_y = new_player_pos.y - GlobalSettings.LOAD_RADIUS
	var max_y = new_player_pos.y + GlobalSettings.LOAD_RADIUS

	# Add chunks to removal queue if they are out of bounds
	for chunk_pos in chunks:
		if chunk_pos.x < min_x or chunk_pos.x > max_x or chunk_pos.y < min_y or chunk_pos.y > max_y:
			# Queue chunk for removal
			_mutex.lock()
			_removal_queue.append(chunk_pos)
			_mutex.unlock()

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
				_mutex.lock()
				_generation_queue.append(pos)
				_mutex.unlock()
			else:
				# Enable or disable collision based on distance to player
				if pos.x >= collision_min_x and pos.x <= collision_max_x and pos.y >= collision_min_y and pos.y <= collision_max_y:
					chunks[pos].enable_collision()
				else:
					chunks[pos].disable_collision()
	
	_semaphore.post()
