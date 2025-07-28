extends Node2D

# Variables 
@export var chunk_size: int = 32 # how many blocks per chunk
@export var world_width: int = 20 # in chunks
@export var world_to_pix_scale: int = 8 # How big a block is in pix
@export var world_height: int = 15 # in chunks
@export var world_seed: int = randi() % 100000 # Random seed for the world generation

const TerrainGenerator := preload("res://src/scripts/terrain_generator.gd")
const TerrainMesher := preload("res://src/scripts/terrain_mesher.gd")


# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var generator = TerrainGenerator.new()
	var mesher = TerrainMesher.new()

	var terrain_data = generator.generate_noise_terrain(world_seed, Vector2i(world_width, world_height), chunk_size)
	var chunks = mesher.mesh_terrain(terrain_data, world_to_pix_scale, chunk_size)

	# Add the chunks to the scene
	for chunk in chunks:
		add_child(chunk)
