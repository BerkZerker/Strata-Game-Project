class_name ChunkManager extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000

@onready var _CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")

# Thread-safe state (protected by _mutex)
var _generation_queue: Array[Vector2i] = [] # Chunk positions waiting to be generated (sorted by priority)
var _generation_queue_set: Dictionary = {} # O(1) lookup for duplicate checking in generation queue
var _build_queue: Array[Dictionary] = [] # [{pos: Vector2i, terrain_data: Array}] ready to build
var _chunks_in_progress: Dictionary = {} # Chunk positions currently being generated (prevents duplicates)
var _player_chunk_for_priority: Vector2i # Cached player chunk for priority sorting in worker thread
var _thread_alive: bool = true
var _generation_paused: bool = false # Backpressure flag when build queue is full

# Main thread state
var _removal_queue: Array[Chunk] = []
var _player_region: Vector2i
var _player_chunk: Vector2i
var _last_sorted_player_chunk: Vector2i # Track last position queues were sorted for
var chunks: Dictionary[Vector2i, Chunk] = {}
var _chunk_pool: Array[Chunk] = [] # Pool of reusable chunk instances

# Thread and synchronization primitives
var _terrain_generator: TerrainGenerator
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore


# Initialization
func _ready() -> void:
	_terrain_generator = TerrainGenerator.new(WORLD_SEED)
	
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_worker_thread_loop)

	# Connect to player movement signals from central SignalBus
	SignalBus.connect("player_chunk_changed", _on_player_chunk_changed)


# The main process loop, handles processing the queues each frame
func _process(_delta: float) -> void:
	# Process chunks from build queue (main thread work)
	_process_build_queue()
	
	# Process chunk removals
	_process_removal_queue()


# Processes chunk builds from the build queue
func _process_build_queue() -> void:
	# Batch extract items from build queue with a single lock
	_mutex.lock()
	var batch_size = mini(_build_queue.size(), GlobalSettings.MAX_CHUNK_BUILDS_PER_FRAME)
	var build_batch: Array[Dictionary] = []
	for i in range(batch_size):
		build_batch.append(_build_queue.pop_front())
	
	# Check if we should resume generation (backpressure relief)
	var should_resume = _generation_paused and _build_queue.size() < GlobalSettings.MAX_BUILD_QUEUE_SIZE / 2.0
	if should_resume:
		_generation_paused = false
	_mutex.unlock()
	
	# Wake worker thread if backpressure was relieved
	if should_resume:
		_semaphore.post()
	
	# Process the batch without holding the lock
	var chunks_to_mark_done: Array[Vector2i] = []
	
	for build_data in build_batch:
		var chunk_pos: Vector2i = build_data["pos"]
		var terrain_data: Array = build_data["terrain_data"]
		var visual_image: Image = build_data["visual_image"]
		
		# Skip if chunk already exists (might have been built while in queue)
		if chunks.has(chunk_pos):
			chunks_to_mark_done.append(chunk_pos)
			continue
		
		# Skip if chunk is out of valid range (player moved away)
		if not _is_chunk_in_valid_range(chunk_pos):
			chunks_to_mark_done.append(chunk_pos)
			continue
		
		# Instantiate and build the chunk (using pool)
		var chunk: Chunk = _get_chunk()
		if chunk.get_parent() == null:
			add_child(chunk)
		
		chunk.generate(terrain_data, chunk_pos)
		chunk.build(visual_image)
		chunks[chunk_pos] = chunk
		chunks_to_mark_done.append(chunk_pos)
	
	# Batch remove from in-progress tracking with a single lock
	if not chunks_to_mark_done.is_empty():
		_mutex.lock()
		for pos in chunks_to_mark_done:
			_chunks_in_progress.erase(pos)
		_mutex.unlock()


# Processes chunk removals from the removal queue
func _process_removal_queue() -> void:
	var removals_this_frame = 0
	
	while removals_this_frame < GlobalSettings.MAX_CHUNK_REMOVALS_PER_FRAME:
		if _removal_queue.is_empty():
			break
		var chunk = _removal_queue.pop_back()
		if is_instance_valid(chunk):
			_recycle_chunk(chunk)
		removals_this_frame += 1


## Converts a chunk position to its containing region position
func _get_chunk_region(chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(chunk_pos.x) / GlobalSettings.REGION_SIZE),
		floori(float(chunk_pos.y) / GlobalSettings.REGION_SIZE)
	)


# Checks if a chunk is within the valid range for loading based on player position
func _is_chunk_in_valid_range(chunk_pos: Vector2i) -> bool:
	# Calculate the chunk's region
	var chunk_region = _get_chunk_region(chunk_pos)
	
	# Calculate removal bounds in REGION coordinates
	var removal_radius = GlobalSettings.LOD_RADIUS + GlobalSettings.REMOVAL_BUFFER
	var min_region = _player_region - Vector2i(removal_radius, removal_radius)
	var max_region = _player_region + Vector2i(removal_radius, removal_radius)
	
	# Check if chunk's region is within bounds
	return chunk_region.x >= min_region.x and chunk_region.x <= max_region.x and chunk_region.y >= min_region.y and chunk_region.y <= max_region.y


# Worker thread loop for chunk generation
func _worker_thread_loop() -> void:
	while true:
		# Wait for work signal
		_semaphore.wait()
		
		# Check if we should exit or pause
		_mutex.lock()
		if not _thread_alive:
			_mutex.unlock()
			break
		
		# Skip processing if backpressure is active
		if _generation_paused:
			_mutex.unlock()
			continue
		_mutex.unlock()
		
		# Process one chunk at a time for responsiveness
		_process_one_chunk()


# Processes a single chunk from the generation queue
func _process_one_chunk() -> void:
	_mutex.lock()
	
	# Check for empty queue
	if _generation_queue.is_empty():
		_mutex.unlock()
		return
	
	# Find the first chunk that isn't already in progress
	var chunk_pos: Vector2i = Vector2i.ZERO
	var found_valid_chunk = false
	
	while not _generation_queue.is_empty():
		chunk_pos = _generation_queue.pop_front()
		_generation_queue_set.erase(chunk_pos) # Keep set in sync
		
		if not _chunks_in_progress.has(chunk_pos):
			found_valid_chunk = true
			break
	
	if not found_valid_chunk:
		_mutex.unlock()
		return
	
	# Mark as in progress
	_chunks_in_progress[chunk_pos] = true
	var has_more_work = not _generation_queue.is_empty()
	
	_mutex.unlock()
	
	# Generate terrain data (thread-safe operation, done outside lock)
	var terrain_data = _terrain_generator.generate_chunk(chunk_pos)
	
	# Generate visual image data in the thread to save main thread time
	var visual_image = _generate_visual_image(terrain_data)
	
	# Add to build queue and check backpressure
	_mutex.lock()
	_build_queue.append({
		"pos": chunk_pos,
		"terrain_data": terrain_data,
		"visual_image": visual_image
	})
	
	# Apply backpressure if build queue is too large
	if _build_queue.size() >= GlobalSettings.MAX_BUILD_QUEUE_SIZE:
		_generation_paused = true
		has_more_work = false # Don't signal for more work
	
	_mutex.unlock()
	
	# Signal for more work only if there's actually more to do
	if has_more_work:
		_semaphore.post()


# Marks chunks for removal based on player region and removal radius
func _mark_chunks_for_removal(center_region: Vector2i, removal_radius: int) -> void:
	# Check all loaded chunks using abs-based bounds check
	var chunks_to_remove: Array[Vector2i] = []
	
	for chunk_pos in chunks.keys():
		var chunk_region = _get_chunk_region(chunk_pos)
		
		# If chunk's region is outside removal bounds, mark for removal
		if absi(chunk_region.x - center_region.x) > removal_radius or absi(chunk_region.y - center_region.y) > removal_radius:
			chunks_to_remove.append(chunk_pos)
	
	# Remove marked chunks (separate loop to avoid modifying dict while iterating)
	for chunk_pos in chunks_to_remove:
		var chunk = chunks.get(chunk_pos)
		if chunk != null:
			chunks.erase(chunk_pos)
			if not _removal_queue.has(chunk):
				_removal_queue.append(chunk)


# Queues new chunks for generation based on player region and generation radius
func _queue_chunks_for_generation(center_region: Vector2i, gen_radius: int) -> void:
	# Collect all chunk positions that need to be generated
	var chunks_to_queue: Array[Vector2i] = []
	var player_chunk = _player_chunk
	
	# Iterate over all regions in generation radius
	for region_x in range(center_region.x - gen_radius, center_region.x + gen_radius + 1):
		for region_y in range(center_region.y - gen_radius, center_region.y + gen_radius + 1):
			# Calculate chunk bounds for this region
			var chunk_start_x = region_x * GlobalSettings.REGION_SIZE
			var chunk_start_y = region_y * GlobalSettings.REGION_SIZE
			
			# Iterate over all chunks in this region
			for cx in range(chunk_start_x, chunk_start_x + GlobalSettings.REGION_SIZE):
				for cy in range(chunk_start_y, chunk_start_y + GlobalSettings.REGION_SIZE):
					var chunk_pos = Vector2i(cx, cy)
					
					# Skip if already loaded
					if chunks.has(chunk_pos):
						continue
					
					chunks_to_queue.append(chunk_pos)
	
	# Update the generation queue (merge with existing, avoiding duplicates)
	# Note: No need to pre-sort chunks_to_queue - we sort the entire queue after merging
	_mutex.lock()
	
	# Use O(1) set lookup instead of iterating the array
	var new_chunks: Array[Vector2i] = []
	for pos in chunks_to_queue:
		if not _generation_queue_set.has(pos) and not _chunks_in_progress.has(pos):
			new_chunks.append(pos)
			_generation_queue_set[pos] = true
	
	# Merge new chunks with existing queue
	if not new_chunks.is_empty():
		_generation_queue = new_chunks + _generation_queue
		_player_chunk_for_priority = player_chunk
		
		# Sort entire queue by distance (only when we added new chunks)
		_generation_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			var dist_a = (a - _player_chunk_for_priority).length_squared()
			var dist_b = (b - _player_chunk_for_priority).length_squared()
			return dist_a < dist_b
		)
	
	var has_work = not _generation_queue.is_empty() and not _generation_paused
	_mutex.unlock()
	
	# Update tracking for smart resorting
	_last_sorted_player_chunk = player_chunk
	
	# Wake worker thread if there's work
	if has_work:
		_semaphore.post()


# Resorts the generation queue based on current player position
func _resort_generation_queue() -> void:
	# Skip if player hasn't moved significantly since last sort
	var player_chunk = _player_chunk
	var distance_moved = (player_chunk - _last_sorted_player_chunk).length_squared()
	if distance_moved < 4: # Only resort if moved more than ~2 chunks
		return
	
	_mutex.lock()
	if _generation_queue.size() < 2:
		_mutex.unlock()
		return
	
	_player_chunk_for_priority = player_chunk
	
	_generation_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var dist_a = (a - player_chunk).length_squared()
		var dist_b = (b - player_chunk).length_squared()
		return dist_a < dist_b
	)
	_mutex.unlock()
	
	_last_sorted_player_chunk = player_chunk


# Resorts the build queue based on current player position
func _resort_build_queue() -> void:
	_mutex.lock()
	if _build_queue.size() < 2:
		_mutex.unlock()
		return
	
	var player_chunk = _player_chunk
	
	# Sort build queue by distance to current player position
	_build_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var dist_a = (a["pos"] - player_chunk).length_squared()
		var dist_b = (b["pos"] - player_chunk).length_squared()
		return dist_a < dist_b
	)
	_mutex.unlock()


# Handler: update internal state when player chunk changes (driven by SignalBus)
func _on_player_chunk_changed(new_player_chunk: Vector2i) -> void:
	if new_player_chunk == _player_chunk:
		return

	# Update player chunk and flag update
	_player_chunk = new_player_chunk

	# Update priority reference for worker thread
	_mutex.lock()
	_player_chunk_for_priority = _player_chunk
	_mutex.unlock()

	# Determine region and trigger appropriate updates
	var new_player_region = _get_chunk_region(_player_chunk)
	if new_player_region != _player_region:
		_player_region = new_player_region
		_on_player_region_changed(_player_region)
	else:
		# Even if region didn't change, re-sort queues for better priority
		_resort_generation_queue()
		_resort_build_queue()


# Handler: update chunk loading when player region changes
func _on_player_region_changed(new_player_region: Vector2i) -> void:
	# Calculate bounds in REGION coordinates
	var gen_radius = GlobalSettings.LOD_RADIUS
	var removal_radius = GlobalSettings.LOD_RADIUS + GlobalSettings.REMOVAL_BUFFER
	
	# --- STEP 1: Mark chunks for removal ---
	_mark_chunks_for_removal(new_player_region, removal_radius)
	
	# --- STEP 2: Queue new chunks for generation ---
	_queue_chunks_for_generation(new_player_region, gen_radius)

	# Resort queues
	_resort_generation_queue()
	_resort_build_queue()


# Retrieves a chunk from the pool or creates a new one if pool is empty
func _get_chunk() -> Chunk:
	if _chunk_pool.is_empty():
		return _CHUNK_SCENE.instantiate()
	else:
		var chunk = _chunk_pool.pop_back()
		return chunk


# Recycles a chunk back into the pool or frees it if pool is full
func _recycle_chunk(chunk: Chunk) -> void:
	if is_instance_valid(chunk):
		chunk.reset()
		if _chunk_pool.size() < GlobalSettings.MAX_CHUNK_POOL_SIZE:
			_chunk_pool.append(chunk)
		else:
			chunk.queue_free() # Free excess chunks

# Helper to generate the chunk image in the worker thread
func _generate_visual_image(terrain_data: Array) -> Image:
	var image = Image.create(GlobalSettings.CHUNK_SIZE, GlobalSettings.CHUNK_SIZE, false, Image.FORMAT_RGBA8)
	
	# Pre-calculate factors to avoid division in loop
	var inv_255 = 1.0 / 255.0
	
	for x in range(GlobalSettings.CHUNK_SIZE):
		for y in range(GlobalSettings.CHUNK_SIZE):
			# Matches logic in original Chunk.gd: _terrain_data[-y - 1][x]
			# terrain_data[0] is bottom row? 
			# Original: _terrain_data[-y - 1][x] where y is 0..31
			# if y=0 -> -1 (last element)
			# if y=31 -> -32 (first element)
			# So we iterate y from 0 to 31, but access array from end backwards.
			var row_index = -y - 1
			var tile_info = terrain_data[row_index][x]
			
			var tile_id = float(tile_info[0])
			var cell_id = float(tile_info[1])
			
			# Set pixel (x, y)
			image.set_pixel(x, y, Color(tile_id * inv_255, cell_id * inv_255, 0, 0))
			
	return image


# Cleanup on exit
func _exit_tree() -> void:
	# Signal thread to stop
	_mutex.lock()
	_thread_alive = false
	_generation_paused = false
	_generation_queue.clear()
	_generation_queue_set.clear()
	_build_queue.clear()
	_chunks_in_progress.clear()
	_mutex.unlock()
	
	# Wake thread so it can exit
	_semaphore.post()
	_thread.wait_to_finish()
