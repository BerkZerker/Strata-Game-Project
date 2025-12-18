class_name CollisionDetector extends RefCounted

# Swept AABB collision detection against raw chunk data
# This class provides collision detection for AABBs (Axis-Aligned Bounding Boxes)
# moving through a tile-based world, checking against the raw chunk data.

var _chunk_manager: ChunkManager


func _init(chunk_manager: ChunkManager) -> void:
	_chunk_manager = chunk_manager


# Performs swept AABB collision detection and returns the collision result
# Parameters:
#   aabb_pos: Current position of the AABB (center)
#   aabb_size: Size of the AABB
#   velocity: Movement velocity for this frame
# Returns: Dictionary with:
#   - position: Final position after collision resolution
#   - velocity: Velocity after collision (may be modified for sliding)
#   - collided: Whether a collision occurred
#   - normal: Collision normal if collided
func sweep_aabb(aabb_pos: Vector2, aabb_size: Vector2, velocity: Vector2) -> Dictionary:
	var result = {
		"position": aabb_pos,
		"velocity": velocity,
		"collided": false,
		"normal": Vector2.ZERO
	}
	
	# If velocity is zero, no movement needed
	if velocity.length_squared() < 0.0001:
		return result
	
	# Calculate AABB bounds
	var half_size = aabb_size * 0.5
	var aabb_min = aabb_pos - half_size
	var aabb_max = aabb_pos + half_size
	
	# Calculate target position
	var target_pos = aabb_pos + velocity
	var target_min = target_pos - half_size
	var target_max = target_pos + half_size
	
	# Determine the range of tiles to check
	var check_min = Vector2(min(aabb_min.x, target_min.x), min(aabb_min.y, target_min.y))
	var check_max = Vector2(max(aabb_max.x, target_max.x), max(aabb_max.y, target_max.y))
	
	# Convert to tile coordinates (floor for min, ceil for max)
	var tile_min = Vector2i(int(floor(check_min.x)), int(floor(check_min.y)))
	var tile_max = Vector2i(int(ceil(check_max.x)), int(ceil(check_max.y)))
	
	# Sweep along X axis first
	var x_collision = _sweep_axis(aabb_pos, half_size, velocity, Vector2.RIGHT, tile_min, tile_max)
	if x_collision.collided:
		result.collided = true
		result.position = x_collision.position
		result.velocity = x_collision.velocity
		result.normal = x_collision.normal
		
		# Update position for Y sweep
		aabb_pos = result.position
		velocity = result.velocity
		half_size = aabb_size * 0.5
		aabb_min = aabb_pos - half_size
		aabb_max = aabb_pos + half_size
		target_pos = aabb_pos + velocity
		target_min = target_pos - half_size
		target_max = target_pos + half_size
		check_min = Vector2(min(aabb_min.x, target_min.x), min(aabb_min.y, target_min.y))
		check_max = Vector2(max(aabb_max.x, target_max.x), max(aabb_max.y, target_max.y))
		tile_min = Vector2i(int(floor(check_min.x)), int(floor(check_min.y)))
		tile_max = Vector2i(int(ceil(check_max.x)), int(ceil(check_max.y)))
	
	# Sweep along Y axis
	var y_collision = _sweep_axis(aabb_pos, half_size, velocity, Vector2.DOWN, tile_min, tile_max)
	if y_collision.collided:
		result.collided = true
		result.position = y_collision.position
		result.velocity = y_collision.velocity
		result.normal = y_collision.normal
	elif not result.collided:
		# No collision on either axis, move to target
		result.position = target_pos
	
	return result


# Sweeps along a single axis and returns collision info
func _sweep_axis(aabb_pos: Vector2, half_size: Vector2, velocity: Vector2, axis: Vector2, tile_min: Vector2i, tile_max: Vector2i) -> Dictionary:
	var result = {
		"position": aabb_pos,
		"velocity": velocity,
		"collided": false,
		"normal": Vector2.ZERO
	}
	
	# Extract axis component
	var axis_velocity = velocity.dot(axis) * axis
	if axis_velocity.length_squared() < 0.0001:
		return result
	
	var target_pos = aabb_pos + axis_velocity
	var step_direction = 1 if axis_velocity.dot(axis) > 0 else -1
	
	# Check all tiles in the sweep area
	var closest_hit_time = 1.0
	var hit_normal = Vector2.ZERO
	
	for tile_x in range(tile_min.x, tile_max.x + 1):
		for tile_y in range(tile_min.y, tile_max.y + 1):
			var tile_world_pos = Vector2(tile_x, tile_y)
			
			# Check if this tile is solid
			if not _chunk_manager.is_solid_at_world_pos(tile_world_pos + Vector2(0.5, 0.5)):
				continue
			
			# Calculate AABB vs tile collision time
			var hit_time = _aabb_vs_tile_sweep(aabb_pos, half_size, axis_velocity, tile_world_pos)
			
			if hit_time >= 0 and hit_time < closest_hit_time:
				closest_hit_time = hit_time
				# Determine collision normal based on which face was hit
				if axis == Vector2.RIGHT:
					hit_normal = Vector2(-step_direction, 0)
				else: # axis == Vector2.DOWN
					hit_normal = Vector2(0, -step_direction)
	
	# If we found a collision, adjust position and velocity
	if closest_hit_time < 1.0:
		result.collided = true
		result.position = aabb_pos + axis_velocity * closest_hit_time
		# Remove velocity component along collision normal
		result.velocity = velocity - velocity.dot(hit_normal) * hit_normal
		result.normal = hit_normal
	else:
		result.position = target_pos
	
	return result


# Calculates the time of collision between a moving AABB and a static tile
# Returns a value between 0 and 1 (or -1 if no collision)
func _aabb_vs_tile_sweep(aabb_pos: Vector2, half_size: Vector2, velocity: Vector2, tile_pos: Vector2) -> float:
	# Tile bounds (tiles are 1x1)
	var tile_min = tile_pos
	var tile_max = tile_pos + Vector2.ONE
	
	# AABB bounds
	var aabb_min = aabb_pos - half_size
	var aabb_max = aabb_pos + half_size
	
	# Calculate entry and exit times for each axis
	var entry_time = Vector2.ZERO
	var exit_time = Vector2.ZERO
	
	# X axis
	if velocity.x > 0:
		entry_time.x = (tile_min.x - aabb_max.x) / velocity.x
		exit_time.x = (tile_max.x - aabb_min.x) / velocity.x
	elif velocity.x < 0:
		entry_time.x = (tile_max.x - aabb_min.x) / velocity.x
		exit_time.x = (tile_min.x - aabb_max.x) / velocity.x
	else:
		# No movement on X axis
		if aabb_max.x <= tile_min.x or aabb_min.x >= tile_max.x:
			return -1.0 # No overlap possible
		entry_time.x = -INF
		exit_time.x = INF
	
	# Y axis
	if velocity.y > 0:
		entry_time.y = (tile_min.y - aabb_max.y) / velocity.y
		exit_time.y = (tile_max.y - aabb_min.y) / velocity.y
	elif velocity.y < 0:
		entry_time.y = (tile_max.y - aabb_min.y) / velocity.y
		exit_time.y = (tile_min.y - aabb_max.y) / velocity.y
	else:
		# No movement on Y axis
		if aabb_max.y <= tile_min.y or aabb_min.y >= tile_max.y:
			return -1.0 # No overlap possible
		entry_time.y = -INF
		exit_time.y = INF
	
	# Find the latest entry time and earliest exit time
	var entry = max(entry_time.x, entry_time.y)
	var exit = min(exit_time.x, exit_time.y)
	
	# Check for collision
	if entry > exit or (entry_time.x < 0 and entry_time.y < 0) or entry > 1.0:
		return -1.0 # No collision
	
	return max(0.0, entry)


# Simple point check for if a position is in solid terrain
func is_point_in_solid(world_pos: Vector2) -> bool:
	return _chunk_manager.is_solid_at_world_pos(world_pos)
