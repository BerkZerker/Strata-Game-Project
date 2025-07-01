@tool
extends TileMapLayer

func _ready() -> void:
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.05
	
	var width = 1000  # Number of tiles horizontally
	var height = 300  # Number of tiles vertically
	
	for x in range(width):
		#var y = int(remap(noise.get_noise_1d(x), -2, 2, 15, height - 1))
		for y in range(height):
			set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
