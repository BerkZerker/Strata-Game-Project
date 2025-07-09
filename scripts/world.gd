extends Node2D

const ChunkScene = preload("res://scenes/chunk.tscn")

@export var world_size_in_chunks = Vector2i(10, 10)
@export var chunk_size = Vector2i(64, 64)
@export var threshold = 0.5

var noise = FastNoiseLite.new()

func _ready():
	noise.seed = randi()
	noise.fractal_octaves = 4
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	generate_world()

func generate_world():
	for y in range(world_size_in_chunks.y):
		for x in range(world_size_in_chunks.x):
			var chunk = ChunkScene.instantiate()
			add_child(chunk)
			var chunk_data = get_chunk_data(x, y)
			chunk.generate_chunk(chunk_data, threshold)
			chunk.position = Vector2(x * chunk_size.x, y * chunk_size.y)

func get_chunk_data(chunk_x, chunk_y):
	var data = []
	for y in range(chunk_size.y + 1):
		var row = []
		for x in range(chunk_size.x + 1):
			var gx = chunk_x * chunk_size.x + x
			var gy = chunk_y * chunk_size.y + y
			row.append(noise.get_noise_2d(gx, gy))
		data.append(row)
	return data
