extends Node

const MarchingSquares = preload("res://marching_squares.gd")

func _ready() -> void:
	
	var iso_level = 0.5
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 1
	noise.frequency = 0.05
	
	var vol_data = []
	
	for x in 50:
		vol_data.append([])
		for y in 50:
			vol_data[x].append(noise.get_noise_2d(x, y))
	
	var edges = MarchingSquares.generate_vertices(vol_data, iso_level)
	var polys = MarchingSquares.bake_polygons(edges, 1.1)

	for p in polys:
		var new_collision_shape = CollisionPolygon2D.new()
		new_collision_shape.polygon = p
		$Node2D/StaticBody2D.add_child(new_collision_shape)
