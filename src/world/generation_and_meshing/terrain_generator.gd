class_name TerrainGenerator extends RefCounted

var world_seed: int
var chunk_size: int
var noise: FastNoiseLite


# Constructor
func _init(generation_seed: int, chunk_size_in_pixels: int) -> void:
	world_seed = generation_seed
	chunk_size = chunk_size_in_pixels
	noise = FastNoiseLite.new()

	# Configure the noise generator - I may move this later
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = world_seed
	noise.frequency = 0.003


func generate_chunk(chunk_pos: Vector2i) -> Array:
	var chunk = []
	var cell_number = 0 # I will need to track this for each material type and track it globally in the generator
	
	for i in range(chunk_size):
		chunk.append([])
		for j in range(chunk_size):
			var value = noise.get_noise_2d(float(chunk_pos.x * chunk_size + i), float(chunk_pos.y * chunk_size + j))

			# Santize the value to be an int - solid is 1 air is 0
			if value > 0.3:
				value = 3 # Stone
			elif value > 0.15:
				value = 1 # Dirt
			elif value > 0.1:
				value = 2 # Grass
			else:
				value = 0 # Air
			
			chunk[i].append([value, cell_number])

	return chunk
