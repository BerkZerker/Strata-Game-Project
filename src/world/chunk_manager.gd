class_name ChunkManager extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation

var _terrain_generator: TerrainGenerator
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore

var _current_player_pos: Vector2i
var _old_player_pos: Vector2i

# Used by multiple threads
var chunks: Dictionary[Vector2i, Chunk] = {} # Dictionary of Vector2i to Chunk objects
var _thread_alive: bool = true
var _generation_queue: Array[Vector2i] = [] # Positions of chunks to generate
var _removal_queue: Array[Chunk] = [] # Chunks to remove
var _recycle_pool: Array[Chunk] = [] # Pool of chunks to reuse


# Setup the chunk manager
func _ready() -> void:
	# Make a new terrain generator with the given seed
	_terrain_generator = TerrainGenerator.new(WORLD_SEED)

	# Set up the thread stuff
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_process_chunk_updates)

	# Connect to player chunk changed signal
	SignalBus.player_chunk_changed.connect(_on_player_chunk_changed)


# Gracefully stop the thread when the node is removed from the scene tree
func _exit_tree():
	_mutex.lock()
	_thread_alive = false # Tell the thread it can shut down permanently
	_mutex.unlock()
	_semaphore.post() # Wake the thread if it's waiting
	_thread.wait_to_finish()


# The main loop for the worker thread to process chunk updates
func _process_chunk_updates() -> void:
	while _thread_alive: # Keep the thread alive until told to stop
		# Wait for work to do
		_semaphore.wait()

		# Work on generating chunks
		while _generation_queue.size() > 0 and _thread_alive:
			_mutex.lock()
			var pos = _generation_queue.pop_back()
			_mutex.unlock()
			if pos == null:
				break

			# Try to recycle, otherwise make a new chunk
			if _recycle_pool.size() > 0:
				# Recycle a chunk from the pool, without removing it from the scene tree
				_mutex.lock()
				var recycled_chunk = _recycle_pool.pop_back()
				_mutex.unlock()
				if recycled_chunk == null:
					continue
				
				# Generate new data for the chunk
				var new_chunk_data = _terrain_generator.generate_chunk(pos)
				var new_collision_shapes = GreedyMeshing.mesh(new_chunk_data)

				# Thread safe versions of generate and build
				recycled_chunk.regenerate(new_chunk_data, new_collision_shapes, pos)
				recycled_chunk.rebuild()

				# And add the recycled chunk to the chunks dictionary
				_mutex.lock()
				chunks[pos] = recycled_chunk
				_mutex.unlock()

			else: # Create a new chunk
				var chunk_scene = load("uid://dbbq2vtjx0w0y") # Thread safe and only used if we can't recycle.
				var new_chunk = chunk_scene.instantiate() # Ditto above

				# Generate data for the chunk
				var chunk_data = _terrain_generator.generate_chunk(pos)
				var collision_shapes = GreedyMeshing.mesh(chunk_data)

				# Threaded versions of generate and build
				new_chunk.generate(chunk_data, collision_shapes, pos)
				new_chunk.build()

				# And add the new chunk to the chunks dictionary
				_mutex.lock()
				chunks[pos] = new_chunk
				_mutex.unlock()

				# Finally, add the new chunk to the scene tree on the main thread
				call_deferred("add_child", new_chunk)
		
		# Check if we still have chunks left over and queue them for deletion
		if _recycle_pool.size() > GlobalSettings.RECYCLE_POOL_MAX_SIZE:
			_mutex.lock()
			for i in range(_recycle_pool.size() - GlobalSettings.RECYCLE_POOL_MAX_SIZE):
				var chunk_to_remove = _recycle_pool.pop_back()
				_removal_queue.append(chunk_to_remove)
			_mutex.unlock()


# Called when the player changes chunk position, updates _current_player_pos
# This will start the chunk updates in _process
func _on_player_chunk_changed(new_player_pos: Vector2i) -> void:
	_current_player_pos = new_player_pos


func _process(_delta: float) -> void:
	# Check if the player has moved to a new chunk
	if _current_player_pos != _old_player_pos:
		# Update old player position
		_old_player_pos = _current_player_pos
		# Calculate the bounds of chunks that should be loaded
		var load_min_x = _current_player_pos.x - GlobalSettings.LOAD_RADIUS
		var load_max_x = _current_player_pos.x + GlobalSettings.LOAD_RADIUS
		var load_min_y = _current_player_pos.y - GlobalSettings.LOAD_RADIUS
		var load_max_y = _current_player_pos.y + GlobalSettings.LOAD_RADIUS
		# Calculate the bounds to enable collision shapes
		var collision_min_x = _current_player_pos.x - GlobalSettings.COLLISION_RADIUS
		var collision_max_x = _current_player_pos.x + GlobalSettings.COLLISION_RADIUS
		var collision_min_y = _current_player_pos.y - GlobalSettings.COLLISION_RADIUS
		var collision_max_y = _current_player_pos.y + GlobalSettings.COLLISION_RADIUS

		# STEP 1: Add out of bounds chunks to the recycle pool
		var recycle_queue: Array = []
		# Add chunks to the recycle pool if they are out of bounds
		for chunk_pos in chunks:
			if chunk_pos.x < load_min_x or chunk_pos.x > load_max_x or chunk_pos.y < load_min_y or chunk_pos.y > load_max_y:
				# Add to recycle queue
				recycle_queue.append(chunk_pos)

		# Do this to avoid modifying the dictionary while iterating over it
		for pos in recycle_queue:
			_recycle_pool.append(chunks[pos]) # Add the chunk to the recycle pool
			_mutex.lock()
			chunks.erase(pos) # Remove it from the active chunks
			_mutex.unlock()

		# STEP 2: Queue new chunks to be generated / recycled
		# Generate new chunks within radius
		for x in range(load_min_x, load_max_x + 1):
			for y in range(load_min_y, load_max_y + 1):
				var pos = Vector2i(x, y)

				# Check if chunk doesn't exist and create it
				if not chunks.has(pos):
					# Generate new chunk
					_mutex.lock()
					_generation_queue.append(pos)
					_mutex.unlock()
				
				else:
					# STEP 3: Update collision shapes to only activate chunks near the player
					# Enable or disable collision based on distance to player
					# Note that `enable_collision` and `disable_collision` are called on the main thread via
					# call_deferred, and thus are thread safe
					if pos.x >= collision_min_x and pos.x <= collision_max_x and pos.y >= collision_min_y and pos.y <= collision_max_y:
						chunks[pos].enable_collision()
					else:
						chunks[pos].disable_collision()

		# STEP 4: Queue chunks for removal if they aren't needed by the recycle pool
		if _removal_queue.size() > 0:
			# Free the chunks in the removal queue
			for chunk in _removal_queue:
				chunk.queue_free()
			_mutex.lock()
			_removal_queue.clear()
			_mutex.unlock()

		# STEP 5: Wake the worker thread
		_semaphore.post()


# PLACEHOLDER
# Just add the new chunk to the generation queue, and wake the thread
func add_chunk(pos: Vector2i) -> void:
	_mutex.lock()
	_generation_queue.append(pos)
	_mutex.unlock()
	_semaphore.post()
