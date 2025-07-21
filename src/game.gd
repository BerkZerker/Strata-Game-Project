@tool
extends Node2D

const MarchingSquares = preload("res://marching_squares.gd")

func _ready() -> void:
	var iso_level = 0.3
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 1
	noise.frequency = 0.08
	
	var chunks = []
	var chunk_size = 16

	for x in range(64):
		if x % chunk_size == 0:
			chunks.append([])
		for y in range(64):
			var value = noise.get_noise_2d(x, y)
			#if value < iso_level:
				#value = 0
			#else:
				#value = 1
			chunks[x / chunk_size].append(value)
			
			
	var marching_squares = MarchingSquares.new()

	#var chunk_data = []
	#for chunk in chunks:
		#var vertices = marching_squares.generate_vertices(chunk, iso_level, 10, Vector2(x / chunk_size, 0), chunk_size)
		#chunk_data.append(vertices)
	
	#var vertices = marching_squares.generate_vertices(vol_data, iso_level, 10)
	#var polygons = marching_squares.bake_polygons(vertices)

	var line_drawer = $Node2D
	
	for vertices in chunks:
		for segment in vertices:
			if segment.size() == 2:
				var line = Line2D.new()
				line.width = 1
				line.default_color = Color(1, 0, 0)
				var point_1 = Vector2(segment[0][0], segment[0][1])
				var point_2 = Vector2(segment[1][0], segment[1][1])
				line.add_point(point_1)
				line.add_point(point_2)
				line_drawer.add_child(line)
	
	#for p in polygons:
		#var polygon = CollisionPolygon2D.new()
		#polygon.polygon = p
		#$Node2D/StaticBody2D.add_child(polygon)
