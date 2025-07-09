extends Node2D

const MarchingSquares = preload("res://scripts/marching_squares.gd")

@onready var mesh_instance = $MeshInstance2D
@onready var static_body = $StaticBody2D

func generate_chunk(data, threshold):
	var result = MarchingSquares.get_mesh_and_polygons(data, threshold)

	# Create visual mesh
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = result.vertices
	arrays[Mesh.ARRAY_INDEX] = result.indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = mesh

	# Create collision polygons
	for polygon in result.polygons:
		var collision_polygon = CollisionPolygon2D.new()
		collision_polygon.polygon = polygon
		static_body.add_child(collision_polygon)
