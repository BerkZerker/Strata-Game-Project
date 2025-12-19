class_name Chunk extends Node2D

# Variables
@onready var _visual_mesh: MeshInstance2D = $MeshInstance2D

static var _shared_quad_mesh: QuadMesh

var _terrain_data: PackedByteArray = PackedByteArray()


# Called when the node is added to the scene.
func _ready() -> void:
	# Initialize the shared mesh once if it doesn't exist
	if not _shared_quad_mesh:
		_shared_quad_mesh = QuadMesh.new()
		_shared_quad_mesh.size = Vector2(GlobalSettings.CHUNK_SIZE, GlobalSettings.CHUNK_SIZE)


# Sets up the chunk's terrain data and position
func generate(chunk_data: PackedByteArray, chunk_pos: Vector2i) -> void:
	_terrain_data = chunk_data # Just a reference, not a copy (COW optimization works well here)
	position = Vector2(chunk_pos.x * GlobalSettings.CHUNK_SIZE, chunk_pos.y * GlobalSettings.CHUNK_SIZE)


# Takes a pre-generated image to create the texture
func build(visual_image: Image) -> void:
	setup_visual_mesh(visual_image)
	visible = true


# Resets the chunk for pooling
func reset() -> void:
	visible = false
	_terrain_data.clear()
	# Always clear texture to prevent memory leaks
	if _visual_mesh.material:
		_visual_mesh.material.set_shader_parameter("chunk_data_texture", null)


# Sets up the mesh and shader data to draw the chunk using a pre-calculated image
func setup_visual_mesh(image: Image):
	# Assign the shared mesh
	_visual_mesh.mesh = _shared_quad_mesh
	_visual_mesh.position = _visual_mesh.mesh.size / 2.0 # Center it

	var data_texture = ImageTexture.create_from_image(image)
	_visual_mesh.material.set_shader_parameter("chunk_data_texture", data_texture)


# Gets terrain data at a specific tile position within the chunk (0-31, 0-31)
func get_tile_at(tile_x: int, tile_y: int) -> Array:
	if tile_y < 0 or tile_y >= GlobalSettings.CHUNK_SIZE:
		return [0, 0] # Return air if out of bounds
	if tile_x < 0 or tile_x >= GlobalSettings.CHUNK_SIZE:
		return [0, 0] # Return air if out of bounds
	
	var index = (tile_y * GlobalSettings.CHUNK_SIZE + tile_x) * 2
	if index >= _terrain_data.size():
		return [0, 0]
		
	return [_terrain_data[index], _terrain_data[index + 1]]


# Gets just the tile ID at a specific position (Optimized for collision - no Array allocation)
func get_tile_id_at(tile_x: int, tile_y: int) -> int:
	if tile_y < 0 or tile_y >= GlobalSettings.CHUNK_SIZE:
		return 0 # Return air if out of bounds
	if tile_x < 0 or tile_x >= GlobalSettings.CHUNK_SIZE:
		return 0 # Return air if out of bounds
	
	var index = (tile_y * GlobalSettings.CHUNK_SIZE + tile_x) * 2
	if index >= _terrain_data.size():
		return 0
		
	return _terrain_data[index]


# Returns the terrain data array
func get_terrain_data() -> PackedByteArray:
	return _terrain_data