extends Node2D

@export var CHUNK_PADDING: int = 64 # How many blocks to pad the chunk by to detect entities

@onready var visual_mesh: MeshInstance2D = $TerrainMesh
@onready var area_2d: Area2D = $Area2D
@onready var static_body: StaticBody2D = $StaticBody2D

var terrain_data = []
var chunk_size: int # Size of the chunk in pixels


# Builds the chunk scene. Should be called after adding the chunk to the scene
# Called before ready. Need to rename
func build(chunk_data: Array, chunk_pos: Vector2i) -> void:
	print('build called')
	terrain_data = chunk_data
	chunk_size = chunk_data.size() # Assuming square chunks

	# Set the chunk's position.
	position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)

	#await self.ready
	#_setup_area_2d()
	#_setup_collision_shapes()

	# Need to figure out how to set up the textures and shaders here


func rebuild() -> void:
	pass # TODO: Implement rebuild logic


# Returns the terrain data for this chunk
func get_terrain_data() -> Array:
	return terrain_data


# Sets the terrain data for this chunk
func set_terrain_data(data: Array) -> void:
	terrain_data = data

# Move code from build to here?
func _ready() -> void:
	_setup_area_2d()
	_setup_collision_shapes()
	_setup_visual_mesh()


func _setup_visual_mesh():
	# MOST OF THIS NEEDS IT'S OWN FUNCTION
	# Pre-load the shader material so we don't load it for every chunk
	#var terrain_material = load("res://terrain.gdshader")
	# Create a new QuadMesh for our chunk
	var quad_mesh = QuadMesh.new()
	
	# The size of the mesh should be the total size of the chunk in pixels
	quad_mesh.size = Vector2(chunk_size, chunk_size)
	
	# Assign the mesh to our MeshInstance2D node
	visual_mesh.mesh = quad_mesh

	# # Create a new ShaderMaterial and assign the shader to it
	# material = ShaderMaterial.new()
	# material.shader = terrain_material
	
	# Assign the material to the mesh instance
	# WHY DO I HAVE TO DO THIS VIA CODE???
	# mesh_instance.material = material
	
	# Center the mesh on the node's origin if desired
	# This makes positioning the chunk based on its top-left corner easier.
	visual_mesh.position = visual_mesh.mesh.size / 2.0

	# Copied over code below
	var data_texture = _create_data_texture()
	visual_mesh.material.set_shader_parameter("chunk_data_texture", data_texture)

# maybe TEMP
# Encodes the terrain data into a texture for the shader
# The _create_data_texture helper function remains exactly the same as before.
func _create_data_texture() -> ImageTexture:
	# ... same code as the previous answer ...
	var image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_R8)
	for x in range(chunk_size):
		for y in range(chunk_size):
			# Encode the terrain data into the color channels
			var block_id = float(terrain_data[-y - 1][x][0])
			var clump_id = float(terrain_data[-y - 1][x][1]) 
			if block_id != 0: # not air
				image.set_pixel(x, y, Color(clump_id / 255.0, 0, 0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0)) # Transparent

	var texture = ImageTexture.create_from_image(image)
	return texture


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
