class_name Chunk extends Node2D

var _static_body: StaticBody2D
var _visual_mesh: MeshInstance2D
var _quad_mesh: QuadMesh
var _collision_shapes: Array

var terrain_data: Array = []


# Main thread only, sets up the data for the chunk. Use call_deferred to call this from the worker thread
func generate(chunk_data: Array, collision_shapes: Array, chunk_pos: Vector2i) -> void:
	terrain_data = chunk_data # Just a reference, not a copy. More memory efficient
	_collision_shapes = collision_shapes
	position = Vector2(chunk_pos.x * GlobalSettings.CHUNK_SIZE, chunk_pos.y * GlobalSettings.CHUNK_SIZE)


# Thread safe version
func regenerate(new_chunk_data: Array, new_collision_shapes: Array, new_chunk_pos: Vector2i) -> void:
	set_deferred("terrain_data", new_chunk_data)
	set_deferred("_collision_shapes", new_collision_shapes)
	set_deferred("position", Vector2(new_chunk_pos.x * GlobalSettings.CHUNK_SIZE, new_chunk_pos.y * GlobalSettings.CHUNK_SIZE))


# Should only be called once on the worker thread, and after generate has been called.
func build() -> void:
	setup_collision_shapes()
	setup_visual_mesh()


# Called from the main thread via call_deferred
func rebuild() -> void:
	call_deferred("setup_collision_shapes")
	call_deferred("setup_visual_mesh")


# Helper function to setup the collision shapes.
# This starts with the shapes disabled.
func setup_collision_shapes() -> void:
	if _static_body == null: # First time setup - worker thread safe
		_static_body = StaticBody2D.new()
		_static_body.set_collision_mask_value(1, false)
		add_child(_static_body)

	# Main or worker thread safe
	# Delete the old shapes
	for child in _static_body.get_children():
		child.queue_free()
	# And setup the new shapes
	for shape in _collision_shapes:
		shape.disabled = true # Start disabled, enable when near player
		_static_body.add_child(shape)


# Sets up the mesh and shader data to draw the chunk.
func setup_visual_mesh():
	# First time setup - worker thread safe
	if _quad_mesh == null:
		_quad_mesh = QuadMesh.new()
		_quad_mesh.size = Vector2(GlobalSettings.CHUNK_SIZE, GlobalSettings.CHUNK_SIZE)

	# First time setup - worker thread safe
	if _visual_mesh == null:
		_visual_mesh = MeshInstance2D.new()
		_visual_mesh.mesh = _quad_mesh # Assign the mesh to our MeshInstance2D node
		_visual_mesh.position = _visual_mesh.mesh.size / 2.0 # Center it
		# Set up the shader material
		_visual_mesh.material = ShaderMaterial.new()
		_visual_mesh.material.shader = load("uid://b4vyqx2a5say4") # terrain.gdshader
		_visual_mesh.material.set_shader_parameter("dirt_texture", load("uid://oe2jckdihhsp")) # dirt.png
		_visual_mesh.material.set_shader_parameter("grass_texture", load("uid://83w5qniwnc00")) # grass.png
		_visual_mesh.material.set_shader_parameter("stone_texture", load("uid://dcbbq2hyi7qx3")) # stone.png
		# And add it to the chunk scene
		add_child(_visual_mesh)

	# Main or worker thread safe
	# This is called every time `setup_visual_mesh` is called to rebuild the chunk visuals
	# Loop over the terrain data to create the image for the shader
	var image = Image.create(GlobalSettings.CHUNK_SIZE, GlobalSettings.CHUNK_SIZE, false, Image.FORMAT_RGBA8) # May need to play with this later to encode different types of data into the shader
	for x in range(GlobalSettings.CHUNK_SIZE):
		for y in range(GlobalSettings.CHUNK_SIZE):
			# Encode the terrain data into the color channels
			var tile_id = float(terrain_data[-y - 1][x][0]) # 0th index is tile id
			var cell_id = float(terrain_data[-y - 1][x][1]) # 1st index is the cell the tile belongs to
			# Encodes the values into the color channels
			var pixel_data = Color(tile_id / 255.0, cell_id / 255.0, 0, 0)
			image.set_pixel(x, y, pixel_data)

	var data_texture = ImageTexture.create_from_image(image)
	_visual_mesh.material.set_shader_parameter("chunk_data_texture", data_texture)


# Main thread only
# Disables the collision shapes 
func disable_collision() -> void:
	for child in _static_body.get_children():
		child.set_deferred("disabled", true)


# Main thread only
# Enables the collision shapes
func enable_collision() -> void:
	for child in _static_body.get_children():
		child.set_deferred("disabled", false)
