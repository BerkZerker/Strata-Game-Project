# marching_squares.gd
# A utility class for the Marching Squares algorithm.
# Takes a 2D array of float values (volumetric_data) and a threshold (iso_level),
# and returns an array of closed polygons (Array[PackedVector2Array]).
#
# This implementation combines ideas from the user's script and the reference file
# to create a robust polygon generation system. It works by first building a graph
# of all contour segments and then tracing that graph to form closed polygons.
extends Node

# This lookup table defines how edges are connected for each of the 16 possible cell configurations.
# We use a standard edge indexing: 0: Top, 1: Right, 2: Bottom, 3: Left.
# Each entry in the array corresponds to a "state" calculated from the cell's corners.
# The value is an array of pairs, where each pair represents two connected edges.
#
# For example, for state 3 (binary 0011), the TopLeft and TopRight corners are "solid".
# This creates a contour that connects the Left edge (3) and the Right edge (1).
#
# Ambiguous cases (states 5 and 10) occur when diagonal corners are solid.
# We must decide whether to separate the contours or connect them. This implementation
# treats them as separate, which is a common approach.
# e.g., State 5 (TopLeft and BottomRight solid) creates two separate segments:
# one connecting Left and Top, and another connecting Right and Bottom.
const EDGE_CONNECTIONS = [
	[],           # 0:  0000 - No corners are solid
	[[3, 0]],     # 1:  0001 - TopLeft
	[[0, 1]],     # 2:  0010 - TopRight
	[[3, 1]],     # 3:  0011 - TopLeft, TopRight
	[[1, 2]],     # 4:  0100 - BottomRight
	[[3, 0], [1, 2]], # 5:  0101 - TopLeft, BottomRight (Ambiguous Case)
	[[0, 2]],     # 6:  0110 - TopRight, BottomRight
	[[3, 2]],     # 7:  0111 - All but BottomLeft
	[[2, 3]],     # 8:  1000 - BottomLeft
	[[2, 0]],     # 9:  1001 - BottomLeft, TopLeft
	[[0, 1], [2, 3]], # 10: 1010 - TopRight, BottomLeft (Ambiguous Case)
	[[2, 1]],     # 11: 1011 - All but TopLeft
	[[1, 3]],     # 12: 1100 - BottomRight, BottomLeft
	[[0, 3]],     # 13: 1101 - All but TopRight
	[[1, 0]],     # 14: 1110 - All but BottomRight
	[],           # 15: 1111 - All corners are solid
]


# Calculates a binary state for a cell based on which corners are above the iso_level.
# The corner order is Top-Left, Top-Right, Bottom-Right, Bottom-Left, which is a
# standard clockwise order for Marching Squares.
static func _get_cell_state(tl: float, tr: float, br: float, bl: float, iso_level: float) -> int:
	var state = 0
	if tl >= iso_level: state |= 1
	if tr >= iso_level: state |= 2
	if br >= iso_level: state |= 4
	if bl >= iso_level: state |= 8
	return state


# Linearly interpolates between two points (p1, p2) to find the exact position
# on the edge where the value is equal to the iso_level.
# v1 and v2 are the data values at p1 and p2.
static func _lerp_point(p1: Vector2, p2: Vector2, v1: float, v2: float, iso_level: float) -> Vector2:
	# Avoid division by zero if the values are the same
	if abs(v1 - v2) < 0.00001:
		return p1
	var t = (iso_level - v1) / (v2 - v1)
	return p1.lerp(p2, t)


# The main function to generate polygons from volumetric data.
static func generate_polygons(volumetric_data: Array, iso_level: float) -> Array[PackedVector2Array]:
	if volumetric_data.is_empty() or volumetric_data[0].is_empty():
		return []

	var point_graph = _build_point_graph(volumetric_data, iso_level)
	var polygons = _trace_polygons_from_graph(point_graph)
	
	return polygons


# Step 1: Build a graph that connects all the vertices of the contours.
# The graph is a dictionary where keys are vertex positions (Vector2) and
# values are arrays of neighboring vertices.
static func _build_point_graph(volumetric_data: Array, iso_level: float) -> Dictionary:
	var point_graph: Dictionary = {}
	var width = volumetric_data.size()
	var height = volumetric_data[0].size()

	# Iterate over each cell in the grid
	for y in range(height - 1):
		for x in range(width - 1):
			# Get the values at the four corners of the cell
			var val_tl = volumetric_data[x][y]
			var val_tr = volumetric_data[x + 1][y]
			var val_br = volumetric_data[x + 1][y + 1]
			var val_bl = volumetric_data[x][y + 1]

			# Determine the cell's state
			var state = _get_cell_state(val_tl, val_tr, val_br, val_bl, iso_level)
			var connections = EDGE_CONNECTIONS[state]

			# If there are no connections in this cell, skip it
			if connections.is_empty():
				continue

			# Get the world positions of the corners
			var pos_tl = Vector2(x, y)
			var pos_tr = Vector2(x + 1, y)
			var pos_br = Vector2(x + 1, y + 1)
			var pos_bl = Vector2(x, y + 1)

			# Calculate the interpolated positions for vertices on each of the four edges
			var point_top = _lerp_point(pos_tl, pos_tr, val_tl, val_tr, iso_level)
			var point_right = _lerp_point(pos_tr, pos_br, val_tr, val_br, iso_level)
			var point_bottom = _lerp_point(pos_bl, pos_br, val_bl, val_br, iso_level)
			var point_left = _lerp_point(pos_tl, pos_bl, val_tl, val_bl, iso_level)
			
			var edge_points = [point_top, point_right, point_bottom, point_left]

			# For each connection pair, add the two points to the graph
			for connection in connections:
				var p1 = edge_points[connection[0]]
				var p2 = edge_points[connection[1]]

				# Add forward connection
				if not point_graph.has(p1): point_graph[p1] = []
				point_graph[p1].append(p2)

				# Add backward connection
				if not point_graph.has(p2): point_graph[p2] = []
				point_graph[p2].append(p1)

	return point_graph


# Step 2: Trace the graph to find all closed loops, which are our polygons.
static func _trace_polygons_from_graph(point_graph: Dictionary) -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	var visited: Dictionary = {} # Use a Dictionary as a Set to track visited points

	for start_point in point_graph:
		# If we have already processed this point as part of another polygon, skip it
		if visited.has(start_point):
			continue

		# Start tracing a new polygon from this unvisited point
		var path: Array[Vector2] = []
		var current_point = start_point
		
		# To start the trace, we need to pick a direction. We set the "previous"
		# point to an impossible value so the loop knows which way to go first.
		var prev_point = Vector2.INF 

		while true:
			# If the point has already been visited in this trace, we have a problem
			# (e.g., a point with more than 2 connections), so we stop.
			# A robust implementation might handle T-junctions here.
			if visited.has(current_point):
				break

			visited[current_point] = true
			path.append(current_point)
			
			var neighbors = point_graph.get(current_point, [])
			
			# For a simple closed loop, each point should have exactly two neighbors.
			# If not, it's an open edge or a complex junction, which we won't trace.
			if neighbors.size() != 2:
				break
			
			# Find the next point in the path. It's the neighbor that is NOT
			# the point we just came from.
			var next_point = neighbors[0]
			if next_point == prev_point:
				next_point = neighbors[1]
			
			prev_point = current_point
			current_point = next_point
			
			# If we've returned to the start, the polygon is complete.
			if current_point == start_point:
				polygons.append(PackedVector2Array(path))
				break
	
	return polygons
