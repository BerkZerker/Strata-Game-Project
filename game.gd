extends Node

const MarchingSquares = preload("res://marching_squares.gd")

func _ready() -> void:
	
	var iso_level = 0.5
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 48394
	noise.frequency = 0.2
	
	var vol_data = []
	
	for x in 10:
		vol_data.append([])
		for y in 10:
			vol_data[x].append(noise.get_noise_2d(x, y))
	
	var marched_data = MarchingSquares.march(vol_data, iso_level)
	
	var new_collision_shape = CollisionPolygon2D.new()
	new_collision_shape.polygon = marched_data
	$Node2D/StaticBody2D.add_child(new_collision_shape)
