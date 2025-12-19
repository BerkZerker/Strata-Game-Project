class_name Player extends CharacterBody2D

# Movement Parameters
@export var speed: float = 180.0
@export var acceleration: float = 1500.0
@export var friction: float = 2000.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 800.0
@export var step_height: float = 6.0
@export var coyote_time: float = 0.1

# Camera / View
@export var zoom_amount: float = 0.1
@export var minimum_zoom: Vector2 = Vector2(0.01, 0.01)
@export var maximum_zoom: Vector2 = Vector2(10.0, 10.0)

# Collision / World
@export var collision_box_size: Vector2 = Vector2(10, 16)

@onready var _camera: Camera2D = $Camera2D

var _current_chunk: Vector2i = Vector2i.ZERO
var _collision_detector: CollisionDetector = null
var _is_on_floor: bool = false
var _coyote_timer: float = 0.0
var _chunk_manager_ref: ChunkManager = null


func setup_chunk_manager(chunk_manager: ChunkManager) -> void:
	_chunk_manager_ref = chunk_manager
	_collision_detector = CollisionDetector.new(_chunk_manager_ref)


func _ready() -> void:
	# Calculate initial player chunk/region
	await get_tree().process_frame
	_update_current_chunk()


func _physics_process(delta: float) -> void:
	if not _collision_detector:
		return

	# Update coyote timer
	if _is_on_floor:
		_coyote_timer = coyote_time
	else:
		_coyote_timer -= delta

	# 1. Apply Gravity
	velocity.y += gravity * delta
	
	# 2. Handle Horizontal Input
	var input_axis = Input.get_axis("move_left", "move_right")
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, input_axis * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	# 3. Handle Jump
	if Input.is_action_just_pressed("jump") and (_is_on_floor or _coyote_timer > 0.0):
		velocity.y = jump_velocity
		_is_on_floor = false
		_coyote_timer = 0.0
	
	# 4. Apply Horizontal Movement (X Axis)
	var start_pos = position
	var x_move = Vector2(velocity.x * delta, 0)
	var result_x = _collision_detector.sweep_aabb(position, collision_box_size, x_move)
		
	# Check for step up opportunity if we hit a wall and are on the floor
	if result_x.collided and _is_on_floor and abs(velocity.x) > 0.1:
		# Try to step up
		if _try_step_up(x_move, start_pos):
			pass
		else:
			# Step failed, accept the collision
			position = result_x.position
			velocity.x = 0 # Stop on wall
	else:
		position = result_x.position
		if result_x.collided:
			velocity.x = 0 # Stop on wall
	
	# 5. Apply Vertical Movement (Y Axis)
	var y_move = Vector2(0, velocity.y * delta)
	var result_y = _collision_detector.sweep_aabb(position, collision_box_size, y_move)
	
	position = result_y.position
	
	# Update Floor State
	if result_y.collided:
		velocity.y = 0 # Stop on floor/ceiling
		if result_y.normal.y < -0.5:
			_is_on_floor = true
		elif result_y.normal.y > 0.5:
			# Hit ceiling
			pass
	else:
		_is_on_floor = false
		
	_update_current_chunk()

# Attempts to step up a small obstacle
# Returns true if the step was successful (position updated)
func _try_step_up(intended_move: Vector2, original_pos: Vector2) -> bool:
	# 1. Lift AABB
	var lifted_pos = original_pos + Vector2(0, -step_height)
	
	# Check if we can actually exist at the lifted position (no ceiling bonk)
	if _collision_detector.intersect_aabb(lifted_pos, collision_box_size):
		return false
	
	# 2. Move Forward at lifted height
	var result_fwd = _collision_detector.sweep_aabb(lifted_pos, collision_box_size, intended_move)
	
	# If we didn't move significantly forward, the step is too deep/blocked
	if result_fwd.position.distance_squared_to(lifted_pos) < 0.1:
		return false
		
	# 3. Snap Down
	# Try to move down by step_height + a bit to ensure contact
	var snap_vec = Vector2(0, step_height * 2.0)
	var result_down = _collision_detector.sweep_aabb(result_fwd.position, collision_box_size, snap_vec)
	
	# We must hit the floor to count as a valid step
	if result_down.collided and result_down.normal.y < -0.5:
		# Validate that the final floor height is within acceptable step range (not a pit)
		# relative to original floor. 
		# But 'step_height' logic usually implies stepping UP. 
		# If we end up lower, it's a step down (which gravity handles).
		# If we end up way higher, that's weird.
		# For now, just accept the position.
		position = result_down.position
		return true
	
	return false

# Emit signals when crossing chunk/region boundaries
func _update_current_chunk() -> void:
	var new_chunk = Vector2i(int(floor(global_position.x / GlobalSettings.CHUNK_SIZE)), int(floor(global_position.y / GlobalSettings.CHUNK_SIZE)))
	if new_chunk != _current_chunk:
		_current_chunk = new_chunk
		SignalBus.emit_signal("player_chunk_changed", _current_chunk)

func _input(event: InputEvent) -> void:
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom *= (1 + zoom_amount)
			if _camera.zoom.x > maximum_zoom.x:
				_camera.zoom = maximum_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom *= (1 - zoom_amount)
			if _camera.zoom.x < minimum_zoom.x:
				_camera.zoom = minimum_zoom
