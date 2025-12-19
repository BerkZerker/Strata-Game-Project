class_name TerrainGenerator extends RefCounted

var _world_seed: int
var _noise: FastNoiseLite


# Constructor
func _init(generation_seed: int) -> void:
	_world_seed = generation_seed
	_noise = FastNoiseLite.new()

	# Configure the noise generator - I may move this later
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.seed = _world_seed
	_noise.frequency = 0.003


# Generates a chunk of terrain data based on the chunk position in chunk coordinates (not tile coordinates)
func generate_chunk(chunk_pos: Vector2i) -> PackedByteArray:
	var chunk_size = GlobalSettings.CHUNK_SIZE
	var data = PackedByteArray()
	data.resize(chunk_size * chunk_size * 2) # 2 bytes per tile: [id, cell_number]
	
	var cell_number = 0 # I will need to track this for each material type and track it globally in the generator

	for i in range(chunk_size): # y
		for j in range(chunk_size): # x
			# Get the noise value for this position (i & j are reversed, don't ask why, nobody knows)
			var value = _noise.get_noise_2d(float(chunk_pos.x * chunk_size + j), float(chunk_pos.y * chunk_size + i))

			var tile_id = 0
			# Santize the value to be an int - solid is 1 air is 0
			if value > 0.3:
				tile_id = 3 # Stone
			elif value > 0.15:
				tile_id = 1 # Dirt
			elif value > 0.1:
				tile_id = 2 # Grass
			else:
				tile_id = 0 # Air
			
			# Store interleaved: [id, cell_number]
			# i is row (y), j is col (x)
			var index = (i * chunk_size + j) * 2
			data[index] = tile_id
			data[index + 1] = cell_number

	return data
