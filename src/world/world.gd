extends Node2D

# Variables 
@export var CHUNK_SIZE: int = 64 # how many blocks per chunk
@export var WORLD_WIDTH: int = 10 # in chunks
@export var WORLD_HEIGHT: int = 10 # in chunks
@export var WORLD_SEED: int = randi() % 100000 # Random seed for the world generation

@onready var chunk_manager = $ChunkManager

var chunks: Array
var pressed: bool = false
var mouse_button: String = "none"

# Runs when the node is added to the scene
func _ready() -> void:
	# Generate the terrain data and build the chunks
	# To be renamed and added as a scene into the world scene.
	#var world_data = TerrainGenerator.generate_noise_terrain(WORLD_SEED, Vector2i(WORLD_WIDTH, WORLD_HEIGHT), CHUNK_SIZE)
	chunk_manager.chunk_size = CHUNK_SIZE
	chunk_manager.world_width = WORLD_WIDTH
	chunk_manager.world_height = WORLD_HEIGHT
	chunk_manager.world_seed = WORLD_SEED
	chunk_manager.generate_world()


# ALl of this is highly sketch
# Temp function but gets the job done. This will be handled elsewhere in the future
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed = true
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouse_button = "left"
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			mouse_button = "right"

	elif event is InputEventMouseButton and not event.pressed:
		pressed = false
		mouse_button = "none"
	
	if event is InputEventMouseButton or InputEventMouseMotion and pressed:
		if mouse_button == "left":
			#edit_terrain(get_global_mouse_position(), 10, 0) # Add solid blocks
			print("break blocks")
		elif mouse_button == "right":
			#edit_terrain(get_global_mouse_position(), 10, 3) # Remove solid blocks
			print("place blocks")
