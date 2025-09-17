class_name Chunk extends Node2D

var static_body: StaticBody2D
var visual_mesh: MeshInstance2D
var quad_mesh: QuadMesh

var terrain_data: Array = []
var chunk_size: int # Size of the chunk in tiles


# Constructor
func generate(chunk_data: Array, chunk_pos: Vector2i) -> void:
	terrain_data = chunk_data # Just a reference, not a copy. More memory efficient
	chunk_size = chunk_data.size() # Assuming square chunks
	position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)


# Should be called after the node is initialized and added to the tree. 
# Should only be called once, after that use rebuild()
func build() -> void:
	setup_collision_shapes()
	setup_visual_mesh()


# Helper function to setup the collision shapes.
# This starts with the shapes disabled.
func setup_collision_shapes() -> void:
	if static_body == null: # First time setup
		static_body = StaticBody2D.new()
		static_body.set_collision_mask_value(1, false)
		add_child(static_body)

	# Run greedy meshing on the local copy of the terrain data
	var shapes = GreedyMeshing.mesh(terrain_data)

	# Delete the old shapes
	for child in static_body.get_children():
		child.queue_free()
	# And setup the new shapes
	for shape in shapes:
		static_body.add_child(shape)


# Sets up the mesh and shader data to draw the chunk.
func setup_visual_mesh():
	# First time setup
	if quad_mesh == null:
		quad_mesh = QuadMesh.new()
		quad_mesh.size = Vector2(chunk_size, chunk_size)
	
	# First time setup
	if visual_mesh == null:
		visual_mesh = MeshInstance2D.new()
		visual_mesh.mesh = quad_mesh # Assign the mesh to our MeshInstance2D node
		visual_mesh.position = visual_mesh.mesh.size / 2.0 # Center it
		# Set up the shader material
		visual_mesh.material = ShaderMaterial.new()
		visual_mesh.material.shader = load("uid://b4vyqx2a5say4") # terrain.gdshader
		visual_mesh.material.set_shader_parameter("dirt_texture", load("uid://oe2jckdihhsp")) # dirt.png
		visual_mesh.material.set_shader_parameter("grass_texture", load("uid://83w5qniwnc00")) # grass.png
		visual_mesh.material.set_shader_parameter("stone_texture", load("uid://dcbbq2hyi7qx3")) # stone.png
		# And add it to the chunk scene
		add_child(visual_mesh)

	# This is called every time `setup_visual_mesh` is called to rebuild the chunk visuals
	# Loop over the terrain data to create the image for the shader
	var image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGBA8) # May need to play with this later to encode different types of data into the shader
	for x in range(chunk_size):
		for y in range(chunk_size):
			# Encode the terrain data into the color channels
			var tile_id = float(terrain_data[-y - 1][x][0]) # 0th index is tile id
			var cell_id = float(terrain_data[-y - 1][x][1]) # 1st index is the cell the tile belongs to
			# Encodes the values into the color channels
			var pixel_data = Color(tile_id / 255.0, cell_id / 255.0, 0, 0)
			image.set_pixel(x, y, pixel_data)

	var data_texture = ImageTexture.create_from_image(image)
	visual_mesh.material.set_shader_parameter("chunk_data_texture", data_texture)


# Disables the collision shapes 
func disable_collision() -> void:
	for child in static_body.get_children():
		child.set_deferred("disabled", true)


# Enables the collision shapes
func enable_collision() -> void:
	for child in static_body.get_children():
		child.set_deferred("disabled", false)
