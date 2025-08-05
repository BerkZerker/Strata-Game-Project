extends Node2D

var collision_shapes = []
var rectangles = []
var terrain_data = []


# TEMP - whole _ready func needs to be cleaned up
# Define constants for clarity
const CHUNK_WIDTH = 64
const CHUNK_HEIGHT = 64
const TILE_SIZE = 1 # In pixels

@onready var mesh_instance: MeshInstance2D = $MeshInstance2D

func _ready():
	# Pre-load the shader material so we don't load it for every chunk
	var terrain_material = preload("res://terrain.gdshader")
	
	# Create a new QuadMesh for our chunk
	var quad_mesh = QuadMesh.new()
	
	# The size of the mesh should be the total size of the chunk in pixels
	var mesh_size = Vector2(CHUNK_WIDTH * TILE_SIZE, CHUNK_HEIGHT * TILE_SIZE)
	quad_mesh.size = mesh_size
	
	# Assign the mesh to our MeshInstance2D node
	mesh_instance.mesh = quad_mesh
	
	# Create a new ShaderMaterial and assign the shader to it
	var material = ShaderMaterial.new()
	material.shader = terrain_material
	
	# Assign the material to the mesh instance
	mesh_instance.material = material
	
	# Center the mesh on the node's origin if desired
	# This makes positioning the chunk based on its top-left corner easier.
	mesh_instance.position = mesh_size / 2.0


func setup_area_2d(chunk_size: int, world_to_pix_scale: int) -> void:
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var chunk_padding = chunk_size # Overlapping padding in blocks. May need tweaking depending on block size.

	# What a mess
	shape.size = Vector2((chunk_size + chunk_padding) * world_to_pix_scale, (chunk_size + chunk_padding) * world_to_pix_scale)
	collision_shape.position = Vector2(shape.size.x / 2.0 - chunk_padding / 2.0 * world_to_pix_scale, shape.size.y / 2.0 - chunk_padding / 2.0 * world_to_pix_scale)
	collision_shape.shape = shape
	$Area2D.add_child(collision_shape)


# Helper function - very temporary
func add_collision_shapes(shapes: Array) -> void:
	for shape in shapes:
		$StaticBody2D.add_child(shape)
		collision_shapes.append(shape)
		shape.set_deferred("disabled", true)
		

func set_terrain_data(data: Array) -> void:
	terrain_data = data


func get_terrain_data() -> Array:
	return terrain_data


# Probably redundant, but makes a unique copy of the chunk data
func add_rectangles(rects: Array) -> void:
	rectangles = rects.duplicate(true)


# Enables the collision shapes when the player enters the area
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		for child in $StaticBody2D.get_children():
			child.set_deferred("disabled", false)


# Disables the collision shapes when the player exits the area
func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		for child in $StaticBody2D.get_children():
			child.set_deferred("disabled", true)
