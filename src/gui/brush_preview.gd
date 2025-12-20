extends Node2D

func _draw() -> void:
	var manager = get_meta("gui_manager")
	if not manager: return
	
	var r = manager._current_brush_size
	var type = manager._current_brush_type
	var color = Color(1, 1, 1, 0.5)
	
	if type == manager.BRUSH_SQUARE:
		# Draw square centered on position
		# Extends from -r to +r, so size is 2r+1? Or just radius?
		# Logic in apply_edit is range(-r, r+1), so it covers indices -r ... r.
		# That's 2r + 1 tiles wide.
		var size = (r * 2 + 1)
		# The center is at (0,0) of this node. 
		# If r=1, range is -1, 0, 1. Size 3.
		# We want to draw a rect from (-r, -r) to (r+1, r+1) in world units (assuming 1 unit = 1 pixel/tile)
		# Actually, world space is usually pixels. If tile size is 1.0 (implied by no scaling).
		# Wait, terrain generator uses pixel coordinates? 
		# Chunk size is 32. 
		# Let's assume 1 unit = 1 tile for simplicity in logic, but standard 2D is pixels.
		# Terrain shader usually maps 1 pixel = 1 tile if using QuadMesh size 32.
		# Let's check GlobalSettings.
		
		# Drawing a rect outlining the tiles
		draw_rect(Rect2(Vector2(-r, -r), Vector2(size, size)), color, false, 1.0)
		
	elif type == manager.BRUSH_CIRCLE:
		draw_circle(Vector2.ZERO, r, color, false, 1.0)
