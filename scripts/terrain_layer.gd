class_name Tile extends Node2D

var terrain_data: Array

@export var width: int = 50
@export var height: int = 50

func _ready() -> void:
	generate_terrain()


func generate_terrain() -> void:
	var noise = FastNoiseLite.new()
	noise.seed = randi()

	for x in range(width):
		terrain_data.append([])
		for y in range(height):
			if noise.get_noise_2d(x, y) > 0:
				terrain_data[x].append(1)
			else:
				terrain_data[x].append(2)
			print(terrain_data[x][y])

func build_terrain() -> void:
	for x in range(len(terrain_data)):
		for y in range(len(terrain_data[x])):
			# Load the Tile scene (replace the path with your actual Tile scene path)
			var tile_scene = preload("res://path/to/Tile.tscn")
			var tile_instance = tile_scene.instantiate()
			add_child(tile_instance)
