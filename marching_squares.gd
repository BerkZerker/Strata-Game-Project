extends Node

# Lookup table
const STATES = [
	[],
	[[2,3]],
	[[1,2]],
	[[1,3]],
	[[0,1]],
	[[0,3], [1, 2]],
	[[0,2]],
	[[0,3]],
	[[0,3]],
	[[0,2]],
	[[0,1], [2, 3]],
	[[0,1]],
	[[1,3]],
	[[1,2]],
	[[2,3]],
	[],
]


# Helper function to calculate the iso_level interpolation factor to smooth edges.
static func find_lerp_factor(corner_a: float, corner_b: float, iso_level: float) -> float:

	var val = (iso_level - corner_a) / (corner_b - corner_a)
	var lerp_factor =  max(min(1, val), 0)

	return lerp_factor

# Helper function to return index for the states lookup table
static func get_state(corner_a: float, corner_b: float, corner_c: float, corner_d: float, iso_level: float) -> int:

	var sa = int((corner_a - iso_level) > 0)
	var sb = int((corner_b - iso_level) > 0)
	var sc = int((corner_c - iso_level) > 0)
	var sd = int((corner_d - iso_level) > 0)

	var state = round(sa * 8 + sb * 4 + sc * 2 + sd * 1)

	return state


# Returns a PackedVec2Array of points representing the polygon baked from the volumetric data.
static func generate_vertices(volumetric_data: Array, iso_level: float, scale: int, start_pos: Vector2i, section_size: Vector2i) -> Array:
	
	var vertices = []
	var width = section_size.x # grid.width
	var height = section_size.y # grid.height

	for x in range(start_pos.x, width + start_pos.x):
		for y in range(start_pos.y, height + start_pos.y):
			
			# x and y in pixels
			var x_pos = x * scale
			var y_pos = y * scale

			# corner values
			var corner_a = volumetric_data[x][y]
			var corner_b = volumetric_data[x][y + 1]
			var corner_c = volumetric_data[x + 1][y + 1]
			var corner_d = volumetric_data[x + 1][y]

			# interpolation factors to used for smoothing
			var lerp_a = find_lerp_factor(corner_a, corner_b, iso_level)
			var lerp_b = find_lerp_factor(corner_b, corner_c, iso_level)
			var lerp_c = find_lerp_factor(corner_d, corner_c, iso_level)
			var lerp_d = find_lerp_factor(corner_a, corner_d, iso_level)

			# interpolated edge point locations
			var interp_a = Vector2(x_pos + lerp_a * scale, y_pos)
			var interp_b = Vector2(x_pos + scale, y_pos + lerp_b * scale)
			var interp_c = Vector2(x_pos + lerp_c * scale, y_pos + scale)
			var interp_d = Vector2(x_pos, y_pos + lerp_d * scale)

			## edge point locations (not interpolated)
			var point_a = [x_pos + 0.5 * scale , y_pos               ] # 01
			var point_b = [x_pos + scale       , y_pos + 0.5 * scale ] # 12
			var point_c = [x_pos + 0.5 * scale , y_pos + scale       ] # 23
			var point_d = [x_pos               , y_pos + 0.5 * scale ] # 30

			#var edge_points = [interp_a, interp_b, interp_c, interp_d]
			var edge_points = [point_a, point_b, point_c, point_d]

			# use our lookup table via helper function to see what shape this is
			var edges = STATES[get_state(corner_a, corner_b, corner_c, corner_d, iso_level)]

			for line in edges:
				var point_1 = edge_points[line[0]]
				var point_2 = edge_points[line[1]]
				vertices.append([point_1, point_2])

	return vertices
