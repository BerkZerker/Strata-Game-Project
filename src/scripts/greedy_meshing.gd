extends Node

# Function to perform greedy meshing on a 2D array
# Returns an array of Rect2 objects representing the meshed rectangles
func mesh(grid: Array) -> Array:
	# Get the dimensions of the grid
	var height = grid.size()
	if height == 0:
		return []
	var width = grid[0].size()
	if width == 0:
		return []
	
	# Create visited array to track processed cells
	var visited = []
	for y in range(height):
		visited.append([])
		for x in range(width):
			visited[y].append(false)
	
	var rectangles = []
	
	# Iterate through each cell
	for y in range(height):
		for x in range(width):
			if visited[y][x] or grid[y][x][0] == 0: # Skip if already visited or empty
				continue
			
			# Find the width of the rectangle
			var rect_width = 1
			while x + rect_width < width and grid[y][x + rect_width][0] == grid[y][x][0] and not visited[y][x + rect_width]:
				rect_width += 1
			
			# Find the height of the rectangle
			var rect_height = 1
			var can_extend = true
			while y + rect_height < height and can_extend:
				for dx in range(rect_width):
					if grid[y + rect_height][x + dx][0] != grid[y][x][0] or visited[y + rect_height][x + dx]:
						can_extend = false
						break
				if can_extend:
					rect_height += 1
			
			# Mark all cells in the rectangle as visited
			for dy in range(rect_height):
				for dx in range(rect_width):
					visited[y + dy][x + dx] = true
			
			# Store the rectangle information
			var rectangle = Rect2(x, y, rect_width, rect_height)
			rectangles.append(rectangle)
	
	return rectangles

# Function to create collision shapes from the meshed rectangles
func create_collision_shapes(rectangles: Array, scale: float) -> Array:
	var shapes = []
	for rect in rectangles:
		var collision_shape = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		
		# Set the size of the rectangle shape
		# Multiply by cell_size to convert from grid coordinates to world coordinates
		shape.size = rect.size * scale
		
		# Set the position of the collision shape
		# Add half the size to center the shape on the grid cells
		collision_shape.position = (rect.position * scale) + (shape.size / 2)

		collision_shape.shape = shape
		shapes.append(collision_shape)
	
	return shapes
