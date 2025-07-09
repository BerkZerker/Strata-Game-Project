const SQUARE_SIZE = 1

static func get_square_case(a, b, c, d, threshold):
	var case = 0
	if a > threshold: case |= 1
	if b > threshold: case |= 2
	if c > threshold: case |= 4
	if d > threshold: case |= 8
	return case

static func get_mesh_and_polygons(data, threshold):
	var vertices = PackedVector2Array()
	var indices = PackedInt32Array()
	var polygons = []
	var edges = {}

	for y in range(len(data) - 1):
		for x in range(len(data[y]) - 1):
			var p1 = Vector2(x, y) * SQUARE_SIZE
			var p2 = Vector2(x + 1, y) * SQUARE_SIZE
			var p3 = Vector2(x + 1, y + 1) * SQUARE_SIZE
			var p4 = Vector2(x, y + 1) * SQUARE_SIZE

			var d1 = data[y][x]
			var d2 = data[y][x+1]
			var d3 = data[y+1][x+1]
			var d4 = data[y+1][x]

			var case = get_square_case(d1, d2, d3, d4, threshold)
			
			var a = p1.lerp(p2, (threshold - d1) / (d2 - d1) if d2 != d1 else 0.5)
			var b = p2.lerp(p3, (threshold - d2) / (d3 - d2) if d3 != d2 else 0.5)
			var c = p3.lerp(p4, (threshold - d3) / (d4 - d3) if d4 != d3 else 0.5)
			var d = p4.lerp(p1, (threshold - d4) / (d1 - d4) if d1 != d4 else 0.5)

			var v_count = len(vertices)

			match case:
				1:
					vertices.append_array([d, c, p4])
					indices.append_array([v_count, v_count + 1, v_count + 2])
					_add_edge(edges, d, c)
				2:
					vertices.append_array([a, d, p1])
					indices.append_array([v_count, v_count + 1, v_count + 2])
					_add_edge(edges, a, d)
				3:
					vertices.append_array([a, c, p4])
					vertices.append_array([a, p1, p4])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5])
					_add_edge(edges, a, c)
				4:
					vertices.append_array([b, a, p2])
					indices.append_array([v_count, v_count + 1, v_count + 2])
					_add_edge(edges, b, a)
				5:
					vertices.append_array([d, c, p4])
					vertices.append_array([b, a, p2])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5])
					_add_edge(edges, d, c)
					_add_edge(edges, b, a)
				6:
					vertices.append_array([b, d, p1])
					vertices.append_array([b, p2, p1])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5])
					_add_edge(edges, b, d)
				7:
					vertices.append_array([b, c, p4])
					vertices.append_array([b, p1, p4])
					vertices.append_array([b, p2, p1])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5, v_count + 6, v_count + 7, v_count + 8])
					_add_edge(edges, b, c)
				8:
					vertices.append_array([c, b, p3])
					indices.append_array([v_count, v_count + 1, v_count + 2])
					_add_edge(edges, c, b)
				9:
					vertices.append_array([d, b, p3])
					vertices.append_array([d, p4, p3])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5])
					_add_edge(edges, d, b)
				10:
					vertices.append_array([a, d, p1])
					vertices.append_array([c, b, p3])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5])
					_add_edge(edges, a, d)
					_add_edge(edges, c, b)
				11:
					vertices.append_array([a, b, p3])
					vertices.append_array([a, p4, p3])
					vertices.append_array([a, p1, p4])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5, v_count + 6, v_count + 7, v_count + 8])
					_add_edge(edges, a, b)
				12:
					vertices.append_array([c, a, p2])
					vertices.append_array([c, p3, p2])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5])
					_add_edge(edges, c, a)
				13:
					vertices.append_array([d, a, p2])
					vertices.append_array([d, p3, p2])
					vertices.append_array([d, p4, p3])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5, v_count + 6, v_count + 7, v_count + 8])
					_add_edge(edges, d, a)
				14:
					vertices.append_array([c, d, p1])
					vertices.append_array([c, p2, p1])
					vertices.append_array([c, p3, p2])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count + 3, v_count + 4, v_count + 5, v_count + 6, v_count + 7, v_count + 8])
					_add_edge(edges, c, d)
				15:
					vertices.append_array([p1, p2, p3, p4])
					indices.append_array([v_count, v_count + 1, v_count + 2, v_count, v_count + 2, v_count + 3])

	polygons = _create_polygons_from_edges(edges)

	return {
		"vertices": vertices,
		"indices": indices,
		"polygons": polygons
	}

static func _add_edge(edges, p1, p2):
	if not edges.has(p1):
		edges[p1] = []
	edges[p1].append(p2)
	if not edges.has(p2):
		edges[p2] = []
	edges[p2].append(p1)

static func _create_polygons_from_edges(edges):
	var polygons = []
	var visited = {}

	for start_point in edges.keys():
		if not visited.has(start_point):
			var path = [start_point]
			var current_point = start_point
			visited[start_point] = true
			
			while true:
				var neighbors = edges[current_point]
				var next_point = -1
				for neighbor in neighbors:
					if not visited.has(neighbor):
						next_point = neighbor
						break
				
				if next_point != -1:
					visited[next_point] = true
					path.append(next_point)
					current_point = next_point
				else:
					break
			
			if len(path) > 1:
				polygons.append(PackedVector2Array(path))

	return polygons
