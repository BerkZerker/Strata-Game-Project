class_name World extends Node2D


@onready var chunk_manager = $ChunkManager

# Temp
var pressed: bool = false
var mouse_button: String = "none"

# Runs when the node is added to the scene
func _ready() -> void:
	# Pass the variables to the chunk_manager to build the world	
	chunk_manager.chunk_size = CHUNK_SIZE
	chunk_manager.lod_distance = LOD_DISTANCE
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
