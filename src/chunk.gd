extends Node2D

var collision_shapes = []
var rectangles = []

# Helper function - very temporary
func add_collision_shapes(shapes: Array) -> void:
	for shape in shapes:
		$StaticBody2D.add_child(shape)
		collision_shapes.append(shape)


# Probably redundant, but makes a unique copy of the chunk data
func add_rectangles(rects: Array) -> void:
	rectangles = rects.duplicate(true)
