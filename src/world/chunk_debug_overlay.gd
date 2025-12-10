class_name ChunkDebugOverlay extends Node2D

# References
var chunk_manager: ChunkManager = null

# Debug settings
@export var show_loaded_regions: bool = true
@export var show_chunk_outlines: bool = true
@export var show_generation_queue: bool = true
@export var show_removal_queue: bool = true
@export var show_queue_info: bool = true

# Colors
const COLOR_LOADED_REGION: Color = Color(0.2, 0.8, 0.2, 0.15)
const COLOR_CHUNK_OUTLINE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_GENERATION_QUEUE: Color = Color(1.0, 1.0, 0.0, 0.4)
const COLOR_REMOVAL_QUEUE: Color = Color(1.0, 0.0, 1.0, 0.4)
const COLOR_IN_PROGRESS: Color = Color(0.0, 1.0, 1.0, 0.4)

# UI elements
var _info_label: Label = null


func _ready() -> void:
	# Create info label
	_info_label = Label.new()
	_info_label.position = Vector2(10, 10)
	_info_label.add_theme_font_size_override("font_size", 12)
	add_child(_info_label)
	
	# Set z-index to draw on top
	z_index = 100


func _process(_delta: float) -> void:
	queue_redraw()
	_update_info_label()


func _draw() -> void:
	if chunk_manager == null:
		return
	
	# Get camera viewport bounds for culling
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	
	var viewport_rect = _get_visible_rect(camera)
	
	# Draw loaded regions overlay
	if show_loaded_regions:
		_draw_loaded_regions(viewport_rect)
	
	# Draw generation queue indicators
	if show_generation_queue:
		_draw_generation_queue()
	
	# Draw removal queue indicators
	if show_removal_queue:
		_draw_removal_queue()
	
	# Draw chunk outlines (drawn last to be on top)
	if show_chunk_outlines:
		_draw_chunk_outlines()


func _get_visible_rect(camera: Camera2D) -> Rect2:
	var viewport_size = get_viewport_rect().size
	var zoom = camera.zoom
	var camera_pos = camera.global_position
	
	var half_size = viewport_size / zoom / 2.0
	return Rect2(camera_pos - half_size, viewport_size / zoom)


func _draw_loaded_regions(viewport_rect: Rect2) -> void:
	var chunk_size = GlobalSettings.CHUNK_SIZE
	var region_size_pixels = GlobalSettings.REGION_SIZE * chunk_size
	
	# Get all loaded chunks to determine which regions to highlight
	var loaded_regions: Dictionary = {}
	
	for chunk_pos in chunk_manager.chunks.keys():
		var region_x = floori(float(chunk_pos.x) / GlobalSettings.REGION_SIZE)
		var region_y = floori(float(chunk_pos.y) / GlobalSettings.REGION_SIZE)
		var region_pos = Vector2i(region_x, region_y)
		loaded_regions[region_pos] = true
	
	# Draw loaded regions
	for region_pos in loaded_regions.keys():
		var region_world_pos = Vector2(region_pos.x * region_size_pixels, region_pos.y * region_size_pixels)
		var region_rect = Rect2(region_world_pos, Vector2(region_size_pixels, region_size_pixels))
		draw_rect(region_rect, COLOR_LOADED_REGION, true)


func _draw_chunk_outlines() -> void:
	if chunk_manager == null:
		return
	
	var chunk_size = GlobalSettings.CHUNK_SIZE
	
	# Draw white outline for each loaded chunk
	for chunk_pos in chunk_manager.chunks.keys():
		var pos = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
		var rect = Rect2(pos, Vector2(chunk_size, chunk_size))
		draw_rect(rect, COLOR_CHUNK_OUTLINE, false, 1.0)


func _draw_generation_queue() -> void:
	if chunk_manager == null:
		return
	
	var chunk_size = GlobalSettings.CHUNK_SIZE
	
	# Access the generation queue (thread-safe)
	chunk_manager._mutex.lock()
	var generation_queue = chunk_manager._generation_queue.duplicate()
	var chunks_in_progress = chunk_manager._chunks_in_progress.duplicate()
	chunk_manager._mutex.unlock()
	
	# Draw rectangles for chunks in generation queue
	for chunk_pos in generation_queue:
		var pos = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
		var rect = Rect2(pos, Vector2(chunk_size, chunk_size))
		draw_rect(rect, COLOR_GENERATION_QUEUE, true)
	
	# Draw rectangles for chunks in progress (different color)
	for chunk_pos in chunks_in_progress.keys():
		var pos = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
		var rect = Rect2(pos, Vector2(chunk_size, chunk_size))
		draw_rect(rect, COLOR_IN_PROGRESS, true)


func _draw_removal_queue() -> void:
	if chunk_manager == null:
		return
	
	var chunk_size = GlobalSettings.CHUNK_SIZE
	
	# Access the removal queue (main thread only, so no mutex needed)
	for chunk in chunk_manager._removal_queue:
		if is_instance_valid(chunk):
			var rect = Rect2(chunk.position, Vector2(chunk_size, chunk_size))
			draw_rect(rect, COLOR_REMOVAL_QUEUE, true)


func _update_info_label() -> void:
	if not show_queue_info or chunk_manager == null:
		_info_label.visible = false
		return
	
	_info_label.visible = true
	
	# Get queue sizes
	chunk_manager._mutex.lock()
	var gen_queue_size = chunk_manager._generation_queue.size()
	var build_queue_size = chunk_manager._build_queue.size()
	var in_progress_size = chunk_manager._chunks_in_progress.size()
	chunk_manager._mutex.unlock()
	
	var removal_queue_size = chunk_manager._removal_queue.size()
	var loaded_chunks = chunk_manager.chunks.size()
	
	# Format info text
	var info_text = "=== CHUNK DEBUG ===\n"
	info_text += "Loaded Chunks: %d\n" % loaded_chunks
	info_text += "Generation Queue: %d\n" % gen_queue_size
	info_text += "In Progress: %d\n" % in_progress_size
	info_text += "Build Queue: %d\n" % build_queue_size
	info_text += "Removal Queue: %d\n" % removal_queue_size
	
	if chunk_manager.player_instance:
		info_text += "\nPlayer Chunk: %s\n" % str(chunk_manager._player_chunk)
		info_text += "Player Region: %s" % str(chunk_manager._player_region)
	
	_info_label.text = info_text


func toggle_loaded_regions() -> void:
	show_loaded_regions = not show_loaded_regions


func toggle_chunk_outlines() -> void:
	show_chunk_outlines = not show_chunk_outlines


func toggle_generation_queue() -> void:
	show_generation_queue = not show_generation_queue


func toggle_removal_queue() -> void:
	show_removal_queue = not show_removal_queue


func toggle_queue_info() -> void:
	show_queue_info = not show_queue_info


func toggle_all() -> void:
	var new_state = not (show_loaded_regions and show_chunk_outlines and show_generation_queue and show_removal_queue and show_queue_info)
	show_loaded_regions = new_state
	show_chunk_outlines = new_state
	show_generation_queue = new_state
	show_removal_queue = new_state
	show_queue_info = new_state
