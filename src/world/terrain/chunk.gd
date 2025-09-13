class_name Chunk extends Node2D

@export var CHUNK_PADDING: int = 64 # How many tiles to pad the chunk by to detect entities

@onready var visual_mesh: MeshInstance2D = $TerrainMesh
@onready var area_2d: Area2D = $Area2D
@onready var static_body: StaticBody2D = $StaticBody2D

var terrain_data: Array = []
var chunk_size: int # Size of the chunk in tiles


# Constructor
func _init(chunk_data: Array, chunk_pos: Vector2i) -> void:
	terrain_data = chunk_data # Just a reference, not a copy. More memory efficient
	chunk_size = chunk_data.size() # Assuming square chunks
	position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)


func _ready() -> void:
	build()

# Should be called after the node is initialized and added to the tree. 
# Should only be called once, after that use rebuild()
func build() -> void:
	_setup_area_2d()
	_setup_collision_shapes()
	_setup_visual_mesh()


# Since arrays are passed by reference, any changes I make to the terrain data
# outside of this script should be reflected on the terrain_data. This means
# all this function has to do is refresh the collision shapes and the visual mesh.
func rebuild() -> void:
	_setup_collision_shapes()
	_setup_visual_mesh()


# Sets up the area2d to detect entities and activate the chunk when one is nearby.
func _setup_area_2d() -> void:
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	# Fancy maths to scale and position it
	shape.size = Vector2(chunk_size + CHUNK_PADDING, chunk_size + CHUNK_PADDING)
	collision_shape.position = Vector2(shape.size.x / 2.0 - CHUNK_PADDING / 2.0, shape.size.y / 2.0 - CHUNK_PADDING / 2.0)
	collision_shape.shape = shape
	area_2d.add_child(collision_shape)


# Helper function to setup the collision shapes.
func _setup_collision_shapes() -> void:
	# Run greedy meshing on the local copy of the terrain data
	var shapes = GreedyMeshing.mesh(terrain_data)

	# Delete the old shapes
	for child in static_body.get_children():
		child.queue_free()

	# Check if the chunk is already active
	var is_active = false
	for body in area_2d.get_overlapping_bodies():
		if body is CharacterBody2D: # For now this is just the player
			is_active = true
			print('body detected during setup! enabled shapes') # This will be helpful when editing terrain
			break

	# And setup the shapes
	if is_active:
		for shape in shapes:
			shape.set_deferred("disabled", false)
			static_body.add_child(shape)
	else:
		for shape in shapes:
			shape.set_deferred("disabled", true)
			static_body.add_child(shape)


func _setup_visual_mesh():
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


# Enables the collision shapes when the player enters the area
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: # For now this is just the player
		for child in static_body.get_children():
			child.set_deferred("disabled", false)


# Disables the collision shapes when the player exits the area
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D: # For now this is just the player
		for child in static_body.get_children():
			child.set_deferred("disabled", true)
