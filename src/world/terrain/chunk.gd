class_name Chunk extends Node2D

@onready var static_body: StaticBody2D = $StaticBody2D
@onready var visual_mesh: MeshInstance2D = $TerrainMesh

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
	# Run greedy meshing on the local copy of the terrain data
	var shapes = GreedyMeshing.mesh(terrain_data)

	# Delete the old shapes
	for child in static_body.get_children():
		child.queue_free()

	# And setup the shapes
	for shape in shapes:
		static_body.add_child(shape)


# Sets up the mesh and shader data to draw the chunk.
func setup_visual_mesh():
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(chunk_size, chunk_size)
	visual_mesh.mesh = quad_mesh # Assign the mesh to our MeshInstance2D node
	visual_mesh.position = visual_mesh.mesh.size / 2.0 # Center it

	# Loop over the terrain data to create the image for the shader
	var image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGBA8) # May need to play with this later to encode different types of data into the shader
	for x in range(chunk_size):
		for y in range(chunk_size):
			# Encode the terrain data into the color channels
			var tile_id = float(terrain_data[-y - 1][x][0]) # 0th index is tile id
			var cell_id = float(terrain_data[-y - 1][x][1]) # 1st index is the cell the tile belongs to

			var pixel_data = Color(tile_id / 255.0, cell_id / 255.0, 0, 0) # Encodes the values into the color channels
			image.set_pixel(x, y, pixel_data)

	var data_texture = ImageTexture.create_from_image(image)
	visual_mesh.material.set_shader_parameter("chunk_data_texture", data_texture)


# Disables the collision shapes 
func disable_collision() -> void:
	#static_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	for child in static_body.get_children():
		child.set_deferred("disabled", true)


# Enables the collision shapes
func enable_collision() -> void:
	#static_body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
	for child in static_body.get_children():
		child.set_deferred("disabled", false)
