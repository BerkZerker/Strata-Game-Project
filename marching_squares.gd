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
static func generate_vertices(volumetric_data, iso_level: float) -> Array:
	
	var vertices = []
	var width = 49 # grid.width
	var height = 49 # grid.height
	var scale = 1 # scales the voxel data to pixels (1 = 1:1 ratio)

	for x in width:
		for y in height:
			
			# x and y in pixels
			var x_pos = x * scale
			var y_pos = y * scale

			# corner values
			var corner_a = volumetric_data[x][y]
			var corner_b = volumetric_data[x][y + 1]
			var corner_c = volumetric_data[x + 1][y + 1]
			var corner_d = volumetric_data[x + 1][y]

			# interpolation factors to used for smoothing
			var interp_a = find_lerp_factor(corner_a, corner_b, iso_level)
			var interp_b = find_lerp_factor(corner_b, corner_c, iso_level)
			var interp_c = find_lerp_factor(corner_d, corner_c, iso_level)
			var interp_d = find_lerp_factor(corner_a, corner_d, iso_level)

			# interpolated edge point locations
			var point_a = Vector2(x_pos + interp_a * scale, y_pos)
			var point_b = Vector2(x_pos + scale, y_pos + interp_b * scale)
			var point_c = Vector2(x_pos + interp_c * scale, y_pos + scale)
			var point_d = Vector2(x_pos, y_pos + interp_d * scale)

			## edge point locations (not interpolated)
			var _a = [x_pos + 0.5 * scale , y_pos               ] # 01
			var _b = [x_pos + scale       , y_pos + 0.5 * scale ] # 12
			var _c = [x_pos + 0.5 * scale , y_pos + scale       ] # 23
			var _d = [x_pos               , y_pos + 0.5 * scale ] # 30

			#var edge_points = [point_a, point_b, point_c, point_d]
			var edge_points = [_a, _b, _c, _d]

			# use our lookup table via helper function to see what shape this is
			var edges = STATES[get_state(corner_a, corner_b, corner_c, corner_d, iso_level)]

			for line in edges:
				var point_1 = edge_points[line[0]]
				var point_2 = edge_points[line[1]]
				vertices.append([point_1, point_2])

	return vertices


# I need to update the generate funciton to use both the un-interpolated data to bake the polygons,
# but then cross-index it with the interpolated data to give smooth, accurate polygons. 
# Note that while running the game you can hover to view variable values in the editor.
static func bake_polygons(segments: Array, tolerance: float = 0.5) -> Array:
	var polygons = []
	return polygons
