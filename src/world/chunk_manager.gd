class_name ChunkManager extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation

@onready var _CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")

var _generation_queue: Array[Vector2i] = [] # Both threads
var _build_queue: Array[Dictionary] = [] # Both threads, holds [{pos, terrain_data}]
var _terrain_generator: TerrainGenerator
var _thread: Thread
var _mutex: Mutex
var _semaphore: Semaphore
var _thread_alive: bool = true
var _player_region: Vector2i

var player_instance: Player = null
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

	# Connect to player region changed signal
	SignalBus.player_region_changed.connect(_on_player_region_changed)

func _process(_delta: float) -> void:
	# Check if the player's position changed
	if player_instance != null:
		var new_player_region = Vector2i(floor(player_instance.global_position.x / (GlobalSettings.CHUNK_SIZE * GlobalSettings.REGION_SIZE)),
										 floor(player_instance.global_position.y / (GlobalSettings.CHUNK_SIZE * GlobalSettings.REGION_SIZE)))
		#if new_player_region != _player_region:
		_player_region = new_player_region
		_on_player_region_changed(_player_region)


	# Process a limited number of chunks from the build queue each frame
	var builds_this_frame = 0
	while builds_this_frame < GlobalSettings.MAX_CHUNK_UPDATES_PER_FRAME and _build_queue.size() > 0 and _thread_alive:
		_mutex.lock()
		var build_data = _build_queue.pop_back()
		_mutex.unlock()
		if build_data == null:
			break

		# Grab the data
		var chunk_pos = build_data["pos"]
		var terrain_data = build_data["terrain_data"]

		# Only build if the chunk doesn't already exist (it might have been built while waiting in the queue)
		if not chunks.has(chunk_pos):
			var chunk: Chunk = _CHUNK_SCENE.instantiate()
			add_child(chunk)
			chunk.generate(terrain_data, chunk_pos)
			chunk.build()
			chunks[chunk_pos] = chunk

		builds_this_frame += 1
		

func _process_chunk_updates() -> void:
	while _thread_alive:
		# Wait for work to do
		_semaphore.wait()

		var regions_to_generate = []

		# Lock and copy the queues
		_mutex.lock()
		regions_to_generate = _generation_queue.duplicate()
		_generation_queue.clear()
		_mutex.unlock()

		# Process chunk generation
		# I can split this up into a check every x chunks if the thread is alive.
		# Generate a list of chunk positions to build and then use a while loop to 
		# work through the queue.
		var chunks_to_build: Array[Dictionary] = []
		for region_pos in regions_to_generate:
			var region_x = region_pos.x * GlobalSettings.REGION_SIZE
			var region_y = region_pos.y * GlobalSettings.REGION_SIZE
			for x in range(region_x, region_x + GlobalSettings.REGION_SIZE):
				for y in range(region_y, region_y + GlobalSettings.REGION_SIZE):
					var chunk_pos = Vector2i(x, y)
					if not chunks.has(chunk_pos) and _thread_alive:
						# Generate the data and collision shapes
						var terrain_data = _terrain_generator.generate_chunk(chunk_pos)
						# Add to build queue
						chunks_to_build.append({"pos": chunk_pos, "terrain_data": terrain_data})

		# Lock and add to the build queue
		_mutex.lock()
		_build_queue += chunks_to_build
		_mutex.unlock()


# Gracefully stop the thread when the node is removed from the scene tree
func _exit_tree():
	_mutex.lock()
	_generation_queue.clear()
	_build_queue.clear()
	_thread_alive = false # Tell the thread it can shut down permanently
	_mutex.unlock()
	_semaphore.post() # Wake the thread if it's waiting
	_thread.wait_to_finish()


func _on_player_region_changed(new_player_pos: Vector2i) -> void:
	# Calculate the bounds of regions that should be loaded
	var min_x = new_player_pos.x - GlobalSettings.LOAD_RADIUS
	var max_x = new_player_pos.x + GlobalSettings.LOAD_RADIUS
	var min_y = new_player_pos.y - GlobalSettings.LOAD_RADIUS
	var max_y = new_player_pos.y + GlobalSettings.LOAD_RADIUS
	
	# First, unload chunks that are too far away
	for chunk_pos in chunks.keys(): # Use keys() to avoid dictionary modification issues
		var region_pos = Vector2i(floor(chunk_pos.x / GlobalSettings.REGION_SIZE), floor(chunk_pos.y / GlobalSettings.REGION_SIZE))
		if region_pos.x < min_x or region_pos.x > max_x or region_pos.y < min_y or region_pos.y > max_y:
			var chunk = chunks[chunk_pos]
			chunks.erase(chunk_pos)
			chunk.queue_free()
			# This is not optimized :( causes lag spikes when moving fast

	var regions_to_generate: Array[Vector2i] = []
	# Generate new regions within radius
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var pos = Vector2i(x, y)

			# Check if region isn't already queued for generation.
			if not _generation_queue.has(pos):
				regions_to_generate.append(pos)
	
	# Lock and update the generation queue
	_mutex.lock()
	_generation_queue = regions_to_generate
	_mutex.unlock()
	# Signal the worker thread that there's work to do
	_semaphore.post()
