class_name ChunkManager2 extends Node2D

# Variables
@export var WORLD_SEED: int = randi() % 1000000 # Random seed for the world generation

@onready var _CHUNK_SCENE: PackedScene = preload("uid://dbbq2vtjx0w0y")

var _generation_queue: Array[Vector2i] = []

var _terrain_generator: TerrainGenerator

var _player_region: Vector2i
var _player_chunk: Vector2i

var player_instance: Player = null # Assigned via game_instance.gd


# Setup the chunk manager
func _ready() -> void:
	# Make a new terrain generator with the given seed
	_terrain_generator = TerrainGenerator.new(WORLD_SEED)


func _process(_delta: float) -> void:
	# Check if the player's position changed (if we have a player)
	if player_instance != null:
		var new_player_chunk = Vector2i(floor(player_instance.global_position.x / GlobalSettings.CHUNK_SIZE),
										floor(player_instance.global_position.y / GlobalSettings.CHUNK_SIZE))
		var new_player_region = Vector2i(floor(new_player_chunk.x / GlobalSettings.REGION_SIZE),
										floor(new_player_chunk.y / GlobalSettings.REGION_SIZE))
		
		if new_player_chunk != _player_chunk: # For cross chunk border updates
			_player_chunk = new_player_chunk
			_on_player_chunk_changed()

		if new_player_region != _player_region: # For cross region border updates
			_player_region = new_player_region
			_on_player_region_changed()

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
	
	# Process a limited number of chunk removals each frame
	var removals_this_frame = 0
	while removals_this_frame < GlobalSettings.MAX_CHUNK_UPDATES_PER_FRAME and _removal_queue.size() > 0:
		var chunk = _removal_queue.pop_back()
		chunk.queue_free()
		removals_this_frame += 0
		

func _process_chunk_updates() -> void:
	pass


func _on_player_chunk_changed() -> void:
	pass

	
func _on_player_region_changed() -> void:
	pass
