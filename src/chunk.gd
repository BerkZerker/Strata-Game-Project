extends Node2D

var collision_shapes = []
var rectangles = []


func setup_area_2d(chunk_size: int, world_to_pix_scale: int) -> void:
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var chunk_padding = 2 # Overlapping padding in blocks. May need tweaking

	shape.size = Vector2((chunk_size + chunk_padding) * world_to_pix_scale, (chunk_size + chunk_padding) * world_to_pix_scale)
	collision_shape.position = Vector2(shape.size.x / 2 - chunk_padding / 2 * world_to_pix_scale, shape.size.y / 2 - chunk_padding / 2 * world_to_pix_scale)


	collision_shape.shape = shape
	$Area2D.add_child(collision_shape)


# Helper function - very temporary
func add_collision_shapes(shapes: Array) -> void:
	for shape in shapes:
		$StaticBody2D.add_child(shape)
		collision_shapes.append(shape)

		shape.set_deferred("disabled", true)


# Probably redundant, but makes a unique copy of the chunk data
func add_rectangles(rects: Array) -> void:
	rectangles = rects.duplicate(true)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		# $StaticBody2D.set_physics_process(true)
		# $StaticBody2D.visible = true
		#$StaticBody2D.set_deferred("disabled", false)
		for child in $StaticBody2D.get_children():
			child.set_deferred("disabled", false)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		# $StaticBody2D.set_physics_process(false)
		# $StaticBody2D.visible = false
		#$StaticBody2D.set_deferred("disabled", true)
		for child in $StaticBody2D.get_children():
			child.set_deferred("disabled", true)
