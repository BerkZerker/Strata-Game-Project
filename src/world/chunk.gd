extends Node2D

@export var CHUNK_PADDING: int = 64 # How many blocks to pad the chunk by to detect entities

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D
@onready var area_2d: Area2D = $Area2D
@onready var static_body: StaticBody2D = $StaticBody2D

var terrain_data = []
var chunk_size: int # Size of the chunk in pixels


# Builds the chunk scene. Should be called after instancing the chunk
func build(chunk_data: Array, chunk_pos: Vector2i) -> void:
	terrain_data = chunk_data
	chunk_size = chunk_data.size() # Assuming square chunks

	# Set the chunk's position.
	position = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)

	_setup_area_2d()
	_setup_collision_shapes()

	# Need to figure out how to set up the textures and shaders here


func rebuild() -> void:
	pass # TODO: Implement rebuild logic


# Returns the terrain data for this chunk
func get_terrain_data() -> Array:
	return terrain_data


# Sets the terrain data for this chunk
func set_terrain_data(data: Array) -> void:
	terrain_data = data


func _setup_mesh_instance(chunk_size: int):
	# MOST OF THIS NEEDS IT'S OWN FUNCTION
	# Pre-load the shader material so we don't load it for every chunk
	var terrain_material = load("res://terrain.gdshader")
	
	# Create a new QuadMesh for our chunk
	var quad_mesh = QuadMesh.new()
	
	# The size of the mesh should be the total size of the chunk in pixels
	var mesh_size = Vector2(chunk_size, chunk_size)
	quad_mesh.size = mesh_size
	
	# Assign the mesh to our MeshInstance2D node
	mesh_instance.mesh = quad_mesh
	
	# Create a new ShaderMaterial and assign the shader to it
	material = ShaderMaterial.new()
	material.shader = terrain_material
	
	# Assign the material to the mesh instance
	# WHY DO I HAVE TO DO THIS VIA CODE???
	mesh_instance.material = material
	
	# Center the mesh on the node's origin if desired
	# This makes positioning the chunk based on its top-left corner easier.
	mesh_instance.position = mesh_size / 2.0


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
