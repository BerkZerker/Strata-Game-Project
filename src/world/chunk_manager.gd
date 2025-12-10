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
var _build_queue: Array[Dictionary] = [] # [{pos: Vector2i, terrain_data: Array}] ready to build
var _chunks_in_progress: Dictionary = {} # Chunk positions currently being generated (prevents duplicates)
var _player_chunk_for_priority: Vector2i # Cached player chunk for priority sorting in worker thread
var _thread_alive: bool = true

# =============================================================================
# MAIN THREAD ONLY STATE
# =============================================================================
var _removal_queue: Array[Chunk] = []
var _player_region: Vector2i
var _player_chunk: Vector2i
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
		else:
			# Even if region didn't change, re-sort the queue for better priority
			_resort_generation_queue()
	
	# Process chunks from build queue (main thread work)
	_process_build_queue()
	
	# Process chunk removals
	_process_removal_queue()


# =============================================================================
# MAIN THREAD: Queue Processing
# =============================================================================

func _process_build_queue() -> void:
	var builds_this_frame = 0
	
	while builds_this_frame < GlobalSettings.MAX_CHUNK_BUILDS_PER_FRAME:
		# Get next chunk to build
		_mutex.lock()
		if _build_queue.is_empty():
			_mutex.unlock()
			break
		var build_data = _build_queue.pop_front() # FIFO - worker adds in priority order
		_mutex.unlock()
		
		var chunk_pos: Vector2i = build_data["pos"]
		var terrain_data: Array = build_data["terrain_data"]
		
		# Skip if chunk already exists (might have been built while in queue)
		if chunks.has(chunk_pos):
			# Still need to remove from in-progress tracking
			_mutex.lock()
			_chunks_in_progress.erase(chunk_pos)
			_mutex.unlock()
			continue
		
		# Instantiate and build the chunk
		var chunk: Chunk = _CHUNK_SCENE.instantiate()
		add_child(chunk)
		chunk.generate(terrain_data, chunk_pos)
		chunk.build()
		chunks[chunk_pos] = chunk
		
		# Remove from in-progress tracking
		_mutex.lock()
		_chunks_in_progress.erase(chunk_pos)
		_mutex.unlock()
		
		builds_this_frame += 1


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
# WORKER THREAD: Terrain Generation
# =============================================================================

func _worker_thread_loop() -> void:
	while true:
		# Wait for work signal
		_semaphore.wait()
		
		# Check if we should exit
		_mutex.lock()
		if not _thread_alive:
			_mutex.unlock()
			break
		_mutex.unlock()
		
		# Process one chunk at a time for responsiveness
		_process_one_chunk()


func _process_one_chunk() -> void:
	# Get the next chunk position to generate
	_mutex.lock()
	if _generation_queue.is_empty():
		_mutex.unlock()
		return
	
	var chunk_pos = _generation_queue.pop_front() # Highest priority (closest to player)
	
	# Skip if already built or in progress
	if _chunks_in_progress.has(chunk_pos):
		_mutex.unlock()
		# Signal ourselves to process the next one
		_semaphore.post()
		return
	
	# Mark as in progress
	_chunks_in_progress[chunk_pos] = true
	_mutex.unlock()
	
	# Generate terrain data (thread-safe operation)
	var terrain_data = _terrain_generator.generate_chunk(chunk_pos)
	
	# Add to build queue
	_mutex.lock()
	_build_queue.append({"pos": chunk_pos, "terrain_data": terrain_data})
	
	# If there's more work, signal ourselves
	if not _generation_queue.is_empty():
		_semaphore.post()
	_mutex.unlock()


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
	# Calculate removal bounds in REGION coordinates
	var min_region = center_region - Vector2i(removal_radius, removal_radius)
	var max_region = center_region + Vector2i(removal_radius, removal_radius)
	
	# Check all loaded chunks
	for chunk_pos in chunks.keys():
		# Convert chunk position to region position
		var chunk_region = Vector2i(
			floori(float(chunk_pos.x) / GlobalSettings.REGION_SIZE),
			floori(float(chunk_pos.y) / GlobalSettings.REGION_SIZE)
		)
		
		# If chunk's region is outside removal bounds, queue for removal
		if chunk_region.x < min_region.x or chunk_region.x > max_region.x or chunk_region.y < min_region.y or chunk_region.y > max_region.y:
			var chunk = chunks[chunk_pos]
			chunks.erase(chunk_pos)
			if not _removal_queue.has(chunk):
				_removal_queue.append(chunk)


func _queue_chunks_for_generation(center_region: Vector2i, gen_radius: int) -> void:
	# Collect all chunk positions that need to be generated
	var chunks_to_queue: Array[Vector2i] = []
	
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
	
	# Sort by distance to player (closest first)
	var player_chunk = _player_chunk
	chunks_to_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var dist_a = (a - player_chunk).length_squared()
		var dist_b = (b - player_chunk).length_squared()
		return dist_a < dist_b
	)
	
	# Update the generation queue (merge with existing, avoiding duplicates)
	_mutex.lock()
	
	# Filter out chunks already in queue or in progress
	var existing_in_queue: Dictionary = {}
	for pos in _generation_queue:
		existing_in_queue[pos] = true
	
	var new_chunks: Array[Vector2i] = []
	for pos in chunks_to_queue:
		if not existing_in_queue.has(pos) and not _chunks_in_progress.has(pos):
			new_chunks.append(pos)
	
	# Prepend new chunks (they're already sorted by priority)
	# Then re-sort the entire queue to maintain priority order
	_generation_queue = new_chunks + _generation_queue
	_player_chunk_for_priority = player_chunk
	
	# Sort entire queue by distance
	_generation_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var dist_a = (a - _player_chunk_for_priority).length_squared()
		var dist_b = (b - _player_chunk_for_priority).length_squared()
		return dist_a < dist_b
	)
	
	var has_work = not _generation_queue.is_empty()
	_mutex.unlock()
	
	# Wake worker thread if there's work
	if has_work:
		_semaphore.post()


func _resort_generation_queue() -> void:
	_mutex.lock()
	if _generation_queue.is_empty():
		_mutex.unlock()
		return
	
	var player_chunk = _player_chunk
	_player_chunk_for_priority = player_chunk
	
	_generation_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var dist_a = (a - player_chunk).length_squared()
		var dist_b = (b - player_chunk).length_squared()
		return dist_a < dist_b
	)
	_mutex.unlock()


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
	_generation_queue.clear()
	_build_queue.clear()
	_chunks_in_progress.clear()
	_mutex.unlock()
	
	# Wake thread so it can exit
	_semaphore.post()
	_thread.wait_to_finish()
