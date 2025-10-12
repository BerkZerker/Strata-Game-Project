class_name ChunkManager extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation

@onready var CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")

var _chunk_pool: Array[Chunk] = [] # Main thread only
var _generation_queue: Array[Vector2i] = [] # Both threads
var _build_queue: Array[Array] = [] # Both threads, holds [pos, terrain_data, collision_shapes]
var _terrain_generator: TerrainGenerator
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore
var _thread_alive: bool = true

var chunks: Dictionary[Vector2i, Chunk] = {} # Main thread only


# Setup the chunk manager
func _ready() -> void:
	# Make a new terrain generator with the given seed
	_terrain_generator = TerrainGenerator.new(WORLD_SEED)

	# Set up the thread stuff
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_process_chunk_updates)

	setup_chunk_pool()

	# Connect to player chunk changed signal
	SignalBus.player_chunk_changed.connect(_on_player_chunk_changed)

func _process(_delta: float) -> void:
	# Process a limited number of chunks from the build queue each frame
	var builds_this_frame = 0
	while builds_this_frame < GlobalSettings.MAX_CHUNK_UPDATES_PER_FRAME and _build_queue.size() > 0 and _thread_alive:
		_mutex.lock()
		var build_data = _build_queue.pop_back()
		_mutex.unlock()
		if build_data == null:
			break

		var chunk_pos = build_data[0]
		var terrain_data = build_data[1]
		var collision_shapes = build_data[2]

		if not chunks.has(chunk_pos):
			var chunk: Chunk
			# Try to reuse a chunk from the pool
			if _chunk_pool.size() > 0:
				chunk = _chunk_pool.pop_back()
			else:
				# Slow but necessary as a failsafe
				chunk = CHUNK_SCENE.instantiate()
				add_child(chunk)
				pass

			chunk.generate(terrain_data, collision_shapes, chunk_pos)
			chunk.build()
			chunks[chunk_pos] = chunk

		builds_this_frame += 1
		

func _process_chunk_updates() -> void:
	while _thread_alive:
		# Wait for work to do
		_semaphore.wait()

		var chunks_to_generate = []

		# Lock and copy the queues
		_mutex.lock()
		chunks_to_generate = _generation_queue.duplicate()
		_generation_queue.clear()
		_mutex.unlock()

		# Process chunk generation
		var chunks_to_build: Array[Array] = []
		for chunk_pos in chunks_to_generate:
			if not chunks.has(chunk_pos):
				# Generate the data and collision shapes
				var terrain_data = _terrain_generator.generate_chunk(chunk_pos)
				var collision_shapes = [] # GreedyMeshing.mesh(terrain_data)

				# Add to build queue
				chunks_to_build.append([chunk_pos, terrain_data, collision_shapes])
		
		# Lock and add to the build queue
		_mutex.lock()
		_build_queue += chunks_to_build
		_mutex.unlock()


# Gracefully stop the thread when the node is removed from the scene tree
func _exit_tree():
	_mutex.lock()
	_generation_queue.clear()
	_build_queue.clear()
	_chunk_pool.clear()
	_thread_alive = false # Tell the thread it can shut down permanently
	_mutex.unlock()
	_semaphore.post() # Wake the thread if it's waiting
	_thread.wait_to_finish()


# Pre-instantiate a pool of chunks for recycling
func setup_chunk_pool() -> void:
	_chunk_pool.clear()
	# How many chunks to pre-instantiate based on load radius
	var num_chunks = (GlobalSettings.LOAD_RADIUS * 2 + 1) * (GlobalSettings.LOAD_RADIUS * 2 + 1)
	# Pre-instantiate chunks for recycling
	for i in range(num_chunks):
		var chunk = CHUNK_SCENE.instantiate()
		_chunk_pool.append(chunk)
		add_child(chunk)


func _on_player_chunk_changed(new_player_pos: Vector2i) -> void:
	# Calculate the bounds of chunks that should be loaded
	var min_x = new_player_pos.x - GlobalSettings.LOAD_RADIUS
	var max_x = new_player_pos.x + GlobalSettings.LOAD_RADIUS
	var min_y = new_player_pos.y - GlobalSettings.LOAD_RADIUS
	var max_y = new_player_pos.y + GlobalSettings.LOAD_RADIUS
	# Calculate the bounds to enable collision shapes
	# var collision_min_x = new_player_pos.x - GlobalSettings.COLLISION_RADIUS
	# var collision_max_x = new_player_pos.x + GlobalSettings.COLLISION_RADIUS
	# var collision_min_y = new_player_pos.y - GlobalSettings.COLLISION_RADIUS
	# var collision_max_y = new_player_pos.y + GlobalSettings.COLLISION_RADIUS
	
	# First, unload chunks that are too far away
	var chunks_to_remove = []
	for chunk_pos in chunks:
		if chunk_pos.x < min_x or chunk_pos.x > max_x or chunk_pos.y < min_y or chunk_pos.y > max_y:
			# Queue chunk for removal
			chunks_to_remove.append(chunk_pos)
	
	# Remove the chunks outside radius and put them in the recycle pool
	for chunk_pos in chunks_to_remove:
		var chunk = chunks[chunk_pos]
		chunks.erase(chunk_pos)
		chunk.disable()
		_chunk_pool.append(chunk) # Add to pool for recycling

	var chunks_to_generate: Array[Vector2i] = []
	# Generate new chunks within radius
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2i(x, y)

			# Check if chunk doesn't exist and create it
			if not chunks.has(pos):
				# Queue chunk for generation
				chunks_to_generate.append(pos)

			# Enable or disable collision based on distance to player
			# if chunks.has(pos): # Check if the chunk exists yet
			# 	if pos.x >= collision_min_x and pos.x <= collision_max_x and pos.y >= collision_min_y and pos.y <= collision_max_y:
			# 		chunks[pos].enable_collision()
			# 	else:
			# 		chunks[pos].disable_collision()
	
	# Lock and update the generation queue
	_mutex.lock()
	_generation_queue += chunks_to_generate
	_mutex.unlock()
	# Signal the worker thread that there's work to do
	_semaphore.post()
