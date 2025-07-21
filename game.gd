@tool
extends Node2D

const GreedyMeshing = preload("res://src/greedy_meshing.gd")

func _ready() -> void:
	# Set up some noise for the terrain generation
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = 1
	noise.frequency = 0.08
	
	var world = []
	var chunk_size = 16
	var width = 2
	var height = 2
	var scale = 10

	for x in range(width):
		world.append([]) # Add a new row to the world array
		for y in range(height):
			# Generate a chunk of noise data
			var chunk = []
			for i in range(chunk_size):
				chunk.append([])
				for j in range(chunk_size):
					var value = noise.get_noise_2d((x * chunk_size + i), (y * chunk_size + j))
					chunk[i].append(value)
			# Add the chunk to the world array
			world[x].append(chunk)
