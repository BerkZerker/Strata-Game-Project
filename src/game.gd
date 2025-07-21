@tool
extends Node2D

# Variables
@export var world_data = []
@export var chunk_size = 16
@export var world_width = 2
@export var world_height = 2
@export var world_to_pix_scale = 10

const GreedyMeshing = preload("res://src/greedy_meshing.gd")

func _ready() -> void:
	# Set up some noise for the terrain generation
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 1
	noise.frequency = 0.08

	# Get an instance of the GreedyMeshing script
	var mesher = GreedyMeshing.new()

	# Generate the world data
	for x in range(world_width):
		world_data.append([]) # Add a new row to the world array
		for y in range(world_height):
			# Generate a chunk of noise data
			var chunk = []
			for i in range(chunk_size):
				chunk.append([])
				for j in range(chunk_size):
					var value = noise.get_noise_2d((x * chunk_size + i), (y * chunk_size + j))
					# Santize the value to be an int - solid is 1 air is 0
					if value > 0:
						value = 1
					else:
						value = 0
					chunk[i].append(value)
			# Add the chunk to the world array
			world_data[x].append(chunk)
	
	for x in range(world_width):
		for y in range(world_height):
			var chunk = world_data[x][y]
			var rectangles = mesher.mesh(chunk, Vector2(x, y), chunk_size)

			# for rect in rectangles:
			# 	rect.position.x += x * chunk_size
			# 	rect.position.y += y * chunk_size

			var collision_shapes = mesher.create_collision_shapes(rectangles, world_to_pix_scale)

			# Add the collision shapes to the scene
			for shape in collision_shapes:
				$StaticBody2D.add_child(shape)
