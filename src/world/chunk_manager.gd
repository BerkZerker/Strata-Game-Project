class_name ChunkManager extends Node2D

# =============================================================================
# CONFIGURATION
# =============================================================================
@export var WORLD_SEED: int = randi() % 1000000

@onready var _CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")

# =============================================================================
# THREAD-SAFE STATE (protected by _mutex)
# =============================================================================
var _generation_queue: Array[Vector2i] = [] # Chunk positions waiting to be generated (sorted by priority)
var _generation_queue_set: Dictionary = {} # O(1) lookup for duplicate checking in generation queue
var _build_queue: Array[Dictionary] = [] # [{pos: Vector2i, terrain_data: Array}] ready to build
var _chunks_in_progress: Dictionary = {} # Chunk positions currently being generated (prevents duplicates)
var _player_chunk_for_priority: Vector2i # Cached player chunk for priority sorting in worker thread
var _thread_alive: bool = true
var _generation_paused: bool = false # Backpressure flag when build queue is full
var _needs_queue_refill: bool = false # Flag to trigger queue refilling in main thread

# =============================================================================
# MAIN THREAD ONLY STATE
# =============================================================================
var _removal_queue: Array[Chunk] = []
var _player_region: Vector2i
var _player_chunk: Vector2i
var _last_sorted_player_chunk: Vector2i # Track last position queues were sorted for
var chunks: Dictionary[Vector2i, Chunk] = {}
var player_instance: Player = null

# Debug overlay
var _debug_overlay: ChunkDebugOverlay = null

# =============================================================================
# THREADING PRIMITIVES
# =============================================================================
var _terrain_generator: TerrainGenerator
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore


func _ready() -> void:
	_terrain_generator = TerrainGenerator.new(WORLD_SEED)
	
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_worker_thread_loop)
	
	# Create debug overlay
	_debug_overlay = ChunkDebugOverlay.new()
	_debug_overlay.chunk_manager = self
	add_child(_debug_overlay)

	# Connect to player movement signals from central SignalBus
	SignalBus.connect("player_chunk_changed", _on_player_chunk_changed)
	SignalBus.connect("player_region_changed", _on_player_region_changed)


func _process(_delta: float) -> void:
	if player_instance == null:
		return
	
	# Handle debug input
	_handle_debug_input()
	
	# Calculate current player chunk and region
	var new_player_chunk = Vector2i(
		floori(player_instance.global_position.x / GlobalSettings.CHUNK_SIZE),
		floori(player_instance.global_position.y / GlobalSettings.CHUNK_SIZE)
	)
	var new_player_region = Vector2i(
		floori(float(new_player_chunk.x) / GlobalSettings.REGION_SIZE),
		floori(float(new_player_chunk.y) / GlobalSettings.REGION_SIZE)
	)
	
	# Check if player moved to a new chunk
	if new_player_chunk != _player_chunk:
		_player_chunk = new_player_chunk
		
		# Update priority reference for worker thread
		_mutex.lock()
		_player_chunk_for_priority = _player_chunk
		_mutex.unlock()
		
		# Check if player moved to a new region
		if new_player_region != _player_region:
			_player_region = new_player_region
			_on_player_region_changed(_player_region)
			# Resort build queue when region changes
			_resort_build_queue()
		else:
			# Even if region didn't change, re-sort queues for better priority
			_resort_generation_queue()
			_resort_build_queue()
	
	# Check if worker thread needs queue refill (smart refilling)
	_mutex.lock()
	var needs_refill = _needs_queue_refill
	if needs_refill:
		_needs_queue_refill = false # Clear flag first to prevent race conditions
	_mutex.unlock()
	
	if needs_refill:
		_queue_chunks_for_generation(_player_region, GlobalSettings.LOD_RADIUS)
	
	# Process chunks from build queue (main thread work)
	_process_build_queue()
	
	# Process chunk removals
	_process_removal_queue()


# =============================================================================
# MAIN THREAD: Queue Processing
# =============================================================================

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
		
		# Skip if chunk already exists (might have been built while in queue)
		if chunks.has(chunk_pos):
			chunks_to_mark_done.append(chunk_pos)
			continue
		
		# Skip if chunk is out of valid range (player moved away)
		if not _is_chunk_in_valid_range(chunk_pos):
			chunks_to_mark_done.append(chunk_pos)
			continue
		
		# Instantiate and build the chunk
		var chunk: Chunk = _CHUNK_SCENE.instantiate()
		add_child(chunk)
		chunk.generate(terrain_data, chunk_pos)
		chunk.build()
		chunks[chunk_pos] = chunk
		chunks_to_mark_done.append(chunk_pos)
	
	# Batch remove from in-progress tracking with a single lock
	if not chunks_to_mark_done.is_empty():
		_mutex.lock()
		for pos in chunks_to_mark_done:
			_chunks_in_progress.erase(pos)
		_mutex.unlock()


func _process_removal_queue() -> void:
	var removals_this_frame = 0
	
	while removals_this_frame < GlobalSettings.MAX_CHUNK_REMOVALS_PER_FRAME:
		if _removal_queue.is_empty():
			break
		var chunk = _removal_queue.pop_back()
		if is_instance_valid(chunk):
			chunk.queue_free()
		removals_this_frame += 1


# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

## Converts a chunk position to its containing region position
func _get_chunk_region(chunk_pos: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(chunk_pos.x) / GlobalSettings.REGION_SIZE),
		floori(float(chunk_pos.y) / GlobalSettings.REGION_SIZE)
	)


func _is_chunk_in_valid_range(chunk_pos: Vector2i) -> bool:
	# Calculate the chunk's region
	var chunk_region = _get_chunk_region(chunk_pos)
	
	# Calculate removal bounds in REGION coordinates
	var removal_radius = GlobalSettings.LOD_RADIUS + GlobalSettings.REMOVAL_BUFFER
	var min_region = _player_region - Vector2i(removal_radius, removal_radius)
	var max_region = _player_region + Vector2i(removal_radius, removal_radius)
	
	# Check if chunk's region is within bounds
	return chunk_region.x >= min_region.x and chunk_region.x <= max_region.x and \
		   chunk_region.y >= min_region.y and chunk_region.y <= max_region.y


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


# =============================================================================
# WORKER THREAD: Terrain Generation
# =============================================================================

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
	
	# Trigger queue refill if running low (smart refilling)
	if _generation_queue.size() < GlobalSettings.GENERATION_QUEUE_LOW_THRESHOLD:
		_needs_queue_refill = true
	
	_mutex.unlock()
	
	# Generate terrain data (thread-safe operation, done outside lock)
	var terrain_data = _terrain_generator.generate_chunk(chunk_pos)
	
	# Add to build queue and check backpressure
	_mutex.lock()
	_build_queue.append({"pos": chunk_pos, "terrain_data": terrain_data})
	
	# Apply backpressure if build queue is too large
	if _build_queue.size() >= GlobalSettings.MAX_BUILD_QUEUE_SIZE:
		_generation_paused = true
		has_more_work = false # Don't signal for more work
	
	_mutex.unlock()
	
	# Signal for more work only if there's actually more to do
	if has_more_work:
		_semaphore.post()


# =============================================================================
# REGION MANAGEMENT
# =============================================================================

func _on_player_region_changed(new_player_region: Vector2i) -> void:
	# Calculate bounds in REGION coordinates
	var gen_radius = GlobalSettings.LOD_RADIUS
	var removal_radius = GlobalSettings.LOD_RADIUS + GlobalSettings.REMOVAL_BUFFER
	
	# --- STEP 1: Mark chunks for removal ---
	_mark_chunks_for_removal(new_player_region, removal_radius)
	
	# --- STEP 2: Queue new chunks for generation ---
	_queue_chunks_for_generation(new_player_region, gen_radius)


func _mark_chunks_for_removal(center_region: Vector2i, removal_radius: int) -> void:
	# Check all loaded chunks using abs-based bounds check
	var chunks_to_remove: Array[Vector2i] = []
	
	for chunk_pos in chunks.keys():
		var chunk_region = _get_chunk_region(chunk_pos)
		
		# If chunk's region is outside removal bounds, mark for removal
		if absi(chunk_region.x - center_region.x) > removal_radius or \
		   absi(chunk_region.y - center_region.y) > removal_radius:
			chunks_to_remove.append(chunk_pos)
	
	# Remove marked chunks (separate loop to avoid modifying dict while iterating)
	for chunk_pos in chunks_to_remove:
		var chunk = chunks.get(chunk_pos)
		if chunk != null:
			chunks.erase(chunk_pos)
			if not _removal_queue.has(chunk):
				_removal_queue.append(chunk)


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
		
		# Limit queue size to prevent memory issues
		# if _generation_queue.size() > GlobalSettings.MAX_GENERATION_QUEUE_SIZE:
		# 	# Remove excess chunks from the end (furthest from player)
		# 	while _generation_queue.size() > GlobalSettings.MAX_GENERATION_QUEUE_SIZE:
		# 		var removed = _generation_queue.pop_back()
		# 		_generation_queue_set.erase(removed)
		
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


## Handler: update internal state when player chunk changes (driven by SignalBus)
func _on_player_chunk_changed(new_player_chunk: Vector2i) -> void:
	if new_player_chunk == _player_chunk:
		return

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
		# Resort build queue when region changes
		_resort_build_queue()
	else:
		# Even if region didn't change, re-sort queues for better priority
		_resort_generation_queue()
		_resort_build_queue()


# =============================================================================
# DEBUG INPUT HANDLING
# =============================================================================

func _handle_debug_input() -> void:
	if _debug_overlay == null:
		return
	
	# F1: Toggle all debug overlays
	if Input.is_action_just_pressed("debug_toggle_all"):
		_debug_overlay.toggle_all()
	
	# F2: Toggle loaded regions
	if Input.is_action_just_pressed("debug_toggle_chunk_borders"):
		_debug_overlay.toggle_loaded_regions()
	
	# F3: Toggle chunk outlines
	if Input.is_action_just_pressed("debug_toggle_region_borders"):
		_debug_overlay.toggle_chunk_outlines()
	
	# F4: Toggle generation queue
	if Input.is_action_just_pressed("debug_toggle_generation_queue"):
		_debug_overlay.toggle_generation_queue()
	
	# F5: Toggle removal queue
	if Input.is_action_just_pressed("debug_toggle_removal_queue"):
		_debug_overlay.toggle_removal_queue()
	
	# F6: Toggle queue info
	if Input.is_action_just_pressed("debug_toggle_queue_info"):
		_debug_overlay.toggle_queue_info()


# =============================================================================
# CLEANUP
# =============================================================================

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
