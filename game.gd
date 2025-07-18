extends Node

const MarchingSquares = preload("res://marching_squares.gd")

func _ready() -> void:
	var iso_level = 0.5
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 1
	noise.frequency = 0.05
	
	var vol_data = []
	
	for x in 52:
		vol_data.append([])
		for y in 52:
			vol_data[x].append(noise.get_noise_2d(x - 1, y  - 1))

	#var edges = MarchingSquares.generate_vertices(vol_data, iso_level)
	var vertices = MarchingSquares.generate_vertices(vol_data, iso_level, 10, Vector2i(1, 1), Vector2i(50, 50))
	var polygons = MarchingSquares.bake_polygons(vertices)

	var line_drawer = $Node2D

	for segment in vertices:
		if segment.size() == 2:
			var line = Line2D.new()
			line.width = 1.5
			line.default_color = Color(1, 0, 0)
			var point_1 = Vector2(segment[0][0], segment[0][1])
			var point_2 = Vector2(segment[1][0], segment[1][1])
			line.add_point(point_1)
			line.add_point(point_2)
			line_drawer.add_child(line)
	
	for p in polygons:
		var polygon = CollisionPolygon2D.new()
		polygon.polygon = p
		$Node2D/StaticBody2D.add_child(polygon)
