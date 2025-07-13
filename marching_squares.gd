extends Node

const LOOKUP = [
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

func march(grid, iso: float, interpolated=true) -> PackedVector2Array:
	
	var edges: PackedVector2Array = PackedVector2Array()
	var width = 10 # grid.width
	var height = 10 # grid.height
	var scale = 1 # scales the voxel data to pixels (1 = 1:1 ratio)

	for i in width:
		for j in height:
			
			var x = i * scale
			var y = j * scale

			var v0 = grid[i][i]
			var v1 = grid[] # keep x and y normal in this code

	return edges
