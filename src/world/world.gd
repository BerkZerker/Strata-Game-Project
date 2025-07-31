extends Node2D

# Variables 
@export var chunk_size: int = 32 # how many blocks per chunk
@export var world_width: int = 20 # in chunks
@export var world_height: int = 15 # in chunks
@export var world_to_pix_scale: int = 8 # How big a block is in pix
@export var world_seed: int = randi() % 100000 # Random seed for the world generation

const TerrainGenerator := preload("res://src/scripts/terrain_generator.gd")
const TerrainMesher := preload("res://src/scripts/terrain_mesher.gd")

var chunk_data = []
var chunk_meshes = []

# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	var generator = TerrainGenerator.new()
	var mesher = TerrainMesher.new()

	chunk_data = generator.generate_noise_terrain(world_seed, Vector2i(world_width, world_height), chunk_size)
	chunk_meshes = mesher.mesh_terrain(chunk_data, world_to_pix_scale, chunk_size)

	# Add the chunks to the scene
	for chunk in chunk_meshes:
		add_child(chunk)

	edit_terrain(Vector2i(233, 450), 1, 1) # Example call to edit terrain


func edit_terrain(position: Vector2i, radius: int, tile_type: int) -> void:
	var current_chunk = chunk_data[position.x / chunk_size / world_to_pix_scale][position.y / chunk_size / world_to_pix_scale]
	print(current_chunk)