extends Node

# Lookup table
const STATES = [
	[],
	[[2, 3]],
	[[1, 2]],
	[[1, 3]],
	[[0, 1]],
	[[0, 3], [1, 2]],
	[[0, 2]],
	[[0, 3]],
	[[0, 3]],
	[[0, 2]],
	[[0, 1], [2, 3]],
	[[0, 1]],
	[[1, 3]],
	[[1, 2]],
	[[2, 3]],
	[],
]


# Helper function to calculate the iso_level interpolation factor to smooth edges.
static func find_lerp_factor(corner_a: float, corner_b: float, iso_level: float) -> float:
	var val = (iso_level - corner_a) / (corner_b - corner_a)
	var lerp_factor = max(min(1, val), 0)

	return lerp_factor

# Helper function to return index for the states lookup table
static func get_state(corner_a: float, corner_b: float, corner_c: float, corner_d: float, iso_level: float) -> int:
	var sa = int((corner_a - iso_level) > 0)
	var sb = int((corner_b - iso_level) > 0)
	var sc = int((corner_c - iso_level) > 0)
	var sd = int((corner_d - iso_level) > 0)

	var state = round(sa * 8 + sb * 4 + sc * 2 + sd * 1)

	return state


# Takes a 2D array and returns a new 2D array with a 1-cell border.
static func pad_2d_array(source_data: Array, padding_value) -> Array:
	# Handle cases where the source data might be empty.
	if source_data.is_empty() or source_data[0].is_empty():
		return []

	var original_width = source_data.size()
	var original_height = source_data[0].size()

	var padded_width = original_width + 2
	var padded_height = original_height + 2

	# --- 1. Create the new, larger grid filled with the padding value ---
	var padded_data = []
	for i in range(padded_width):
		var new_column = []
		new_column.resize(padded_height)
		new_column.fill(padding_value)
		padded_data.append(new_column)

	# --- 2. Copy the original data into the center of the new grid ---
	for x in range(original_width):
		for y in range(original_height):
			# The "+ 1" offset ensures the data is placed in the middle,
			# leaving a 1-cell border on all sides.
			padded_data[x + 1][y + 1] = source_data[x][y]
			
	return padded_data


# Returns an Array of points representing the verticies calculated from the volumetric data.
static func generate_vertices(data: Array, iso_level: float, scale: int, start_pos: Vector2i, section_size: Vector2i) -> Array:
	var vertices = []
	var width = section_size.x
	var height = section_size.y

	data = pad_2d_array(data, 0.0) # Pad the data to avoid index errors

	for x in range(start_pos.x, width + start_pos.x):
		for y in range(start_pos.y, height + start_pos.y):
			# x and y in pixels - swap them because... it freaking does not work otherwise.
			var x_pos = y * scale
			var y_pos = x * scale

			# corner values from data
			var corner_a = data[x][y]
			var corner_b = data[x][y + 1]
			var corner_c = data[x + 1][y + 1]
			var corner_d = data[x + 1][y]

			# interpolation factors to used for smoothing
			var lerp_a = find_lerp_factor(corner_a, corner_b, iso_level)
			var lerp_b = find_lerp_factor(corner_b, corner_c, iso_level)
			var lerp_c = find_lerp_factor(corner_d, corner_c, iso_level)
			var lerp_d = find_lerp_factor(corner_a, corner_d, iso_level)

			# interpolated edge point locations
			var point_a = Vector2(x_pos + lerp_a * scale, y_pos)
			var point_b = Vector2(x_pos + scale, y_pos + lerp_b * scale)
			var point_c = Vector2(x_pos + lerp_c * scale, y_pos + scale)
			var point_d = Vector2(x_pos, y_pos + lerp_d * scale)
			var edge_points = [point_a, point_b, point_c, point_d]

			# use our lookup table via helper function to see what shape this is
			# we use the edges to determine which shape to use, but then we need to find 
			# the actual points we pull from the interpolated edge points
			var edges = STATES[get_state(corner_a, corner_b, corner_c, corner_d, iso_level)]

			for line in edges:
				# Calculate the endpoints of each line
				var point_1 = edge_points[line[0]]
				var point_2 = edge_points[line[1]]

				# Add the edge to the vertices list
				vertices.append([point_1, point_2])

	return vertices


static func bake_polygons(vertices: Array) -> Array:
	# Step 1: Build an adjacency list (a "connections" dictionary).
	# This maps each point to a list of its neighbors. This is much more
	# efficient for pathfinding than repeatedly searching the original edges array.
	var connections = {}
	for edge in vertices:
		var p1 = edge[0]
		var p2 = edge[1]
		
		# Ensure each point has an entry in the dictionary.
		if not connections.has(p1):
			connections[p1] = []
		if not connections.has(p2):
			connections[p2] = []
			
		# Add the connection in both directions.
		connections[p1].append(p2)
		connections[p2].append(p1)

	var polygons = []
	# Use a dictionary as a "Set" to keep track of points that we have
	# already assigned to a polygon. This prevents us from processing the
	# same point multiple times or creating duplicate polygons.
	var visited_points = {}

	# Step 2: Iterate through every unique point we found.
	for start_point in connections.keys():
		# If we have already included this point in a polygon, skip it.
		if visited_points.has(start_point):
			continue

		# Found an unvisited point, so it must be the start of a new polygon.
		# Begin tracing the path from here.
		var new_poly = PackedVector2Array()
		var current_point = start_point
		
		# Loop until the path can no longer be extended.
		while true:
			# Add the current point to our new polygon chain and mark it as visited.
			new_poly.append(current_point)
			visited_points[current_point] = true
			
			var neighbors = connections[current_point]
			var next_point = null

			# Find the next connected point that we haven't visited yet.
			for neighbor in neighbors:
				if not visited_points.has(neighbor):
					next_point = neighbor
					break # Found our next step, so we can stop searching neighbors.
			
			# If we couldn't find an unvisited neighbor, it means we've either
			# completed a closed loop or reached the end of an open line.
			if next_point == null:
				break
			
			# If we found a next point, make it the current point for the next loop iteration.
			current_point = next_point
			
		# The path tracing is complete for this polygon, so add it to our list.
		polygons.append(new_poly)
		
	return polygons
