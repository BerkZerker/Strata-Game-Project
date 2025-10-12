class_name Chunk extends Node2D

@onready var _static_body: StaticBody2D = $StaticBody2D
@onready var _visual_mesh: MeshInstance2D = $MeshInstance2D
@onready var _collision_shapes: Array = $StaticBody2D.get_children()


var terrain_data: Array = []


func generate(chunk_data: Array, collision_shapes: Array, chunk_pos: Vector2i) -> void:
	terrain_data = chunk_data # Just a reference, not a copy. More memory efficient
	#_collision_shapes = collision_shapes
	position = Vector2(chunk_pos.x * GlobalSettings.CHUNK_SIZE, chunk_pos.y * GlobalSettings.CHUNK_SIZE)


func build() -> void:
	#setup_collision_shapes()
	setup_visual_mesh()
	visible = true


func disable() -> void:
	# Disable the chunk visually and physically
	visible = true
	#disable_collision()


# Helper function to setup the collision shapes.
# This starts with the shapes disabled.
func setup_collision_shapes() -> void:
	# Delete the old shapes
	for child in _static_body.get_children():
		child.queue_free()
	# And setup the new shapes
	for shape in _collision_shapes:
		shape.disabled = true # Start disabled, enable when near player
		_static_body.add_child(shape)


# Sets up the mesh and shader data to draw the chunk.
func setup_visual_mesh():
	# Set up the quad mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(GlobalSettings.CHUNK_SIZE, GlobalSettings.CHUNK_SIZE)
	_visual_mesh.mesh = quad_mesh # Assign the mesh to our MeshInstance2D node
	_visual_mesh.position = _visual_mesh.mesh.size / 2.0 # Center it

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
