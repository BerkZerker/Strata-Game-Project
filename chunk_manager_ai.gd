class_name ChunkManagerAI extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation
@export var MAX_CHUNKS_PER_FRAME: int = 4 # Maximum number of chunks to process in one frame

const CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")

enum ChunkState {
	NONE, # Chunk doesn't exist
	QUEUED, # Chunk is queued for generation
	GENERATING, # Chunk is being generated
	READY, # Chunk is fully generated and active
	QUEUED_REMOVE # Chunk is queued for removal
}

var chunks: Dictionary # Stores the actual chunk nodes
var chunk_states: Dictionary # Stores the state of each chunk position
var terrain_generator: TerrainGenerator

# Threading
var _thread: Thread
var _mutex: Mutex
var _should_exit: bool = false
var _chunk_operation_semaphore: Semaphore

# Operation queues
var _chunk_gen_queue: Array[Dictionary] # Array of {pos: Vector2i, priority: float}
var _chunk_remove_queue: Array[Vector2i]

# Processing state
var _processing_chunks: int = 0


# Thread worker function
func _thread_worker() -> void:
	while not _should_exit:
		_chunk_operation_semaphore.wait() # Wait for work
		
		if _should_exit:
			break
			
		_mutex.lock()
		var current_processing = _processing_chunks
		_mutex.unlock()
		
		# Only process if we're under the limit
		if current_processing >= MAX_CHUNKS_PER_FRAME:
			continue
			
		_mutex.lock()
		# Sort generation queue by priority if there are items
		if _chunk_gen_queue.size() > 0:
			_chunk_gen_queue.sort_custom(func(a, b): return a.priority < b.priority)
			
		# Get chunks to process while respecting the limit
		var chunks_to_generate = _chunk_gen_queue.slice(0, MAX_CHUNKS_PER_FRAME - current_processing)
		var chunks_to_remove = _chunk_remove_queue.slice(0, MAX_CHUNKS_PER_FRAME - current_processing)
		
		# Update queues
		for i in range(chunks_to_generate.size()):
			_chunk_gen_queue.remove_at(0)
		for i in range(chunks_to_remove.size()):
			_chunk_remove_queue.remove_at(0)
			
		_processing_chunks += chunks_to_generate.size() + chunks_to_remove.size()
		_mutex.unlock()
		
		# Process chunk removals
		for chunk_pos in chunks_to_remove:
			if chunk_states.get(chunk_pos, ChunkState.NONE) == ChunkState.QUEUED_REMOVE:
				call_deferred("_remove_chunk", chunk_pos)
		
		# Process chunk generation
		for chunk_data in chunks_to_generate:
			var pos = chunk_data.pos
			if chunk_states.get(pos, ChunkState.NONE) == ChunkState.QUEUED:
				chunk_states[pos] = ChunkState.GENERATING
				var terrain_data = terrain_generator.generate_chunk(pos)
				call_deferred("_add_chunk", pos, terrain_data)
		
		# Update processing count
		_mutex.lock()
		_processing_chunks = max(0, _processing_chunks - (chunks_to_generate.size() + chunks_to_remove.size()))
		_mutex.unlock()

func _add_chunk(pos: Vector2i, chunk_data: Array) -> void:
	_mutex.lock()
	if chunk_states.get(pos, ChunkState.NONE) == ChunkState.GENERATING:
		var new_chunk = CHUNK_SCENE.instantiate()
		new_chunk.generate(chunk_data, pos)
		chunks[pos] = new_chunk
		chunk_states[pos] = ChunkState.READY
		add_child(new_chunk)
		new_chunk.build()
	_mutex.unlock()


func _remove_chunk(pos: Vector2i) -> void:
	_mutex.lock()
	if chunk_states.get(pos, ChunkState.NONE) == ChunkState.QUEUED_REMOVE:
		if chunks.has(pos):
			chunks[pos].queue_free()
			chunks.erase(pos)
		chunk_states.erase(pos)
	_mutex.unlock()


func _calculate_chunk_priority(chunk_pos: Vector2i, player_pos: Vector2i) -> float:
	# Lower priority value means higher priority
	return chunk_pos.distance_to(player_pos)


# Setup the chunk manager
func _ready() -> void:
	chunks = {}
	chunk_states = {}
	terrain_generator = TerrainGenerator.new(WORLD_SEED)
	
	# Initialize threading components
	_thread = Thread.new()
	_mutex = Mutex.new()
	_chunk_operation_semaphore = Semaphore.new()
	_chunk_gen_queue = []
	_chunk_remove_queue = []
	_processing_chunks = 0
	
	# Start the worker thread
	_thread.start(_thread_worker.bind())
	
	# Connect to player chunk changed signal
	SignalBus.player_chunk_changed.connect(_on_player_chunk_changed)

func _exit_tree() -> void:
	# Signal the thread to exit and wait for it
	_should_exit = true
	_chunk_operation_semaphore.post() # Wake up the thread so it can exit
	_thread.wait_to_finish()
	
	# Clean up remaining chunks
	for chunk in chunks.values():
		chunk.queue_free()
	chunks.clear()
	chunk_states.clear()


func _on_player_chunk_changed(new_player_pos: Vector2i) -> void:
	# Calculate the bounds of chunks that should be loaded
	var min_x = new_player_pos.x - GlobalSettings.LOAD_RADIUS
	var max_x = new_player_pos.x + GlobalSettings.LOAD_RADIUS
	var min_y = new_player_pos.y - GlobalSettings.LOAD_RADIUS
	var max_y = new_player_pos.y + GlobalSettings.LOAD_RADIUS

	_mutex.lock()
	# First, find chunks that are too far away
	for chunk_pos in chunks.keys():
		if chunk_pos.x < min_x or chunk_pos.x > max_x or chunk_pos.y < min_y or chunk_pos.y > max_y:
			if chunk_states[chunk_pos] == ChunkState.READY:
				chunk_states[chunk_pos] = ChunkState.QUEUED_REMOVE
				_chunk_remove_queue.append(chunk_pos)

	# Queue new chunks for generation with priority based on distance
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2i(x, y)
			var state = chunk_states.get(pos, ChunkState.NONE)
			if state == ChunkState.NONE:
				chunk_states[pos] = ChunkState.QUEUED
				var priority = _calculate_chunk_priority(pos, new_player_pos)
				_chunk_gen_queue.append({"pos": pos, "priority": priority})
	_mutex.unlock()
	
	# Signal the worker thread that there's work to do
	_chunk_operation_semaphore.post()
