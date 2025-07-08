extends Node2D

const CHUNK := preload("res://scenes/Chunk.tscn")
const CHUNK_SIZE := 8
const SQUARE_SIZE := 16

@export var height := 64
@export var width := 128
var v_chunks: int = ceil(float(height) / float(CHUNK_SIZE))
var h_chunks: int = ceil(float(width) / float(CHUNK_SIZE))
var chunks := []
var altered_chunks := {}
#FIX NOISE- AIR SHOULD ALWAYS BE ZERO, ROCK SHOULD ALWAYS BE 1 INSIDE

func _ready() -> void:
	get_tree().debug_collisions_hint = true
	randomize()
	generate_world(_get_noise(randi()))

func _process(delta_time: float) -> void:
	if(Input.is_action_just_pressed("place_terrain")):
		place_terrain(get_global_mouse_position(), 50.0, 1.0)
	if(Input.is_action_just_pressed("destroy_terrain")):
		explosion(get_global_mouse_position(), 50.0, 1.0)

func _get_noise(noise_seed: int) -> Array:  #priv mark?
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.03
	
	var n_max := 0.0
	var n_avg := 0.0
	for i in range(height):
		for j in range(width):
			var n = abs(noise.get_noise_2d(j,i))
			n_avg += n
			if n > n_max:
				n_max = n
	n_avg /= height * width
	
	var data = []
	for i in range(v_chunks * CHUNK_SIZE + 1): #debug
		data.append([])
		for j in range(h_chunks * CHUNK_SIZE + 1):
			data[i].append(clamp(noise.get_noise_2d(j, i) / n_avg + 1.0, 0.0, 2.0) / 2.0)
	
	return data

func generate_world(terrain_data: Array) -> void:
	chunks.resize(v_chunks)
	for i in range(v_chunks):
		chunks[i] = []
		chunks[i].resize(h_chunks)
		for j in range(h_chunks):
			chunks[i][j] = CHUNK.instantiate()
			chunks[i][j].set_size(CHUNK_SIZE, SQUARE_SIZE)
			chunks[i][j].position = Vector2(j, i) * CHUNK_SIZE * SQUARE_SIZE
			for k in range(CHUNK_SIZE + 1):
				for l in range(CHUNK_SIZE + 1):
					chunks[i][j].vertices[k][l] = terrain_data[i * CHUNK_SIZE + k][j * CHUNK_SIZE + l]
			$Chunks.add_child(chunks[i][j])
	for chunk in $Chunks.get_children():
		chunk.initalize_mesh()

func set_vertex(row: int, col: int, value: float, add: bool = false) -> void:
	if row < 0 or col < 0 or row > height or col > width:
		return
	
	var chunk_row: int = (row - 1) / (CHUNK_SIZE)
	var chunk_col: int = (col - 1) / (CHUNK_SIZE)
	var vertex_row := (row - chunk_row * CHUNK_SIZE) % (CHUNK_SIZE + 1)
	var vertex_col := (col - chunk_col * CHUNK_SIZE) % (CHUNK_SIZE + 1)
	
	if add:
		value += chunks[chunk_row][chunk_col].vertices[vertex_row][vertex_col]
	
	value = clamp(value, 0.0, 1.0)
	
	var chunk = chunks[chunk_row][chunk_col]
	chunk.vertices[vertex_row][vertex_col] = value
	altered_chunks[chunk] = true
	
	var v_edge := vertex_row == CHUNK_SIZE
	var v_bound := chunk_row < v_chunks - 1
	var h_edge := vertex_col == CHUNK_SIZE
	var h_bound := chunk_col < h_chunks - 1
	if v_bound and v_edge:
		chunk = chunks[chunk_row + 1][chunk_col] 
		chunk.vertices[0][vertex_col] = value
		altered_chunks[chunk] = true
	if h_bound and h_edge:
		chunk = chunks[chunk_row][chunk_col + 1] 
		chunk.vertices[vertex_row][0] = value
		altered_chunks[chunk] = true
	if v_bound and v_edge and h_bound and h_edge:
		chunk = chunks[chunk_row + 1][chunk_col + 1]
		chunk.vertices[0][0] = value
		altered_chunks[chunk] = true

func update_chunks(): #unoptimized debug function
	for chunk in altered_chunks.keys():
		chunk.initalize_mesh()
	altered_chunks.clear()
	

func explosion(location: Vector2, radius: float, intensity: float) -> void:
	radius /= SQUARE_SIZE
	location /= SQUARE_SIZE
	var cell_radius = ceil(radius) + 1
	var current := location.round() - Vector2(cell_radius, cell_radius)
	for i in range(cell_radius * 2):
		for j in range(cell_radius * 2):
			set_vertex(current.y + i, current.x + j, max(0.0, 1.0 - min(1.0, Vector2(current.x + j, current.y + i).distance_to(location) / radius)) * -intensity, true) #make this prettier
	update_chunks()
	
func place_terrain(location: Vector2, radius: float, intensity: float) -> void:
	radius /= SQUARE_SIZE
	location /= SQUARE_SIZE
	var cell_radius = ceil(radius) + 1
	var current := location.round() - Vector2(cell_radius, cell_radius)
	for i in range(cell_radius * 2):
		for j in range(cell_radius * 2):
			set_vertex(current.y + i, current.x + j, max(0.0, 1.0 - min(1.0, Vector2(current.x + j, current.y + i).distance_to(location) / radius)) * intensity, true)
	update_chunks()
