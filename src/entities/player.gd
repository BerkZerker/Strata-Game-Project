class_name Player extends CharacterBody2D

@export var speed: int = 300
#@export var JUMP_VELOCITY: int = -250
#@export var STEP_HEIGHT: int = 8
#@export var COYOTE_TIME: float = 0.2
@export var zoom_amount: float = 0.1
@export var minimum_zoom: Vector2 = Vector2(0.001, 0.001)
@export var maximum_zoom: Vector2 = Vector2(100, 100)
@export var collision_box_size: Vector2 = Vector2(14, 14) # Size of the player's collision box
@export var chunk_manager_path: NodePath = NodePath("../ChunkManager") # Path to ChunkManager node

# @onready var _sprite: Sprite2D = $Sprite2D
@onready var _camera: Camera2D = $Camera2D
#@onready var _coyote_timer: Timer = $CoyoteTimer

#var _was_on_floor: bool = false
var _current_chunk: Vector2i = Vector2i.ZERO
var _collision_detector: CollisionDetector = null

func _ready() -> void:
	# Calculate initial player chunk/region
	await get_tree().process_frame
	_update_current_chunk()
	
	# Get reference to ChunkManager and create collision detector
	if not chunk_manager_path.is_empty():
		var chunk_manager = get_node(chunk_manager_path) as ChunkManager
		if chunk_manager:
			_collision_detector = CollisionDetector.new(chunk_manager)
		else:
			push_warning("Player: ChunkManager not found at path: ", chunk_manager_path)

func _physics_process(delta: float) -> void:
	# Apply swept AABB collision detection against raw chunk data
	if _collision_detector:
		var movement = velocity * delta
		var collision_result = _collision_detector.sweep_aabb(position, collision_box_size, movement)
		
		# Update position based on collision result
		position = collision_result.position
		
		# If we collided, update velocity for sliding behavior
		if collision_result.collided:
			velocity = collision_result.velocity / delta
	else:
		# Fallback to simple movement if collision detector not ready
		position += velocity * delta
	
	_update_current_chunk()


# func handle_step_up() -> void:
	# Only check for steps if we're moving and on the floor
	# if velocity.x != 0 and is_on_floor():
	# 	var check_shapecast = right_shapecast if velocity.x > 0 else left_shapecast

	# 	# Check if there's an obstacle in front
	# 	if check_shapecast.is_colliding():
	# 		var original_pos = check_shapecast.position

	# 		for i in range(STEP_HEIGHT):
	# 			check_shapecast.position.y -= 1
	# 			check_shapecast.force_shapecast_update()

	# 			if not check_shapecast.is_colliding():
	# 				# We can step up! Move the player up
	# 				was_on_floor = true
	# 				coyote_timer.stop()
	# 				position.y -= i + 1
	# 				break

	# 		check_shapecast.position = original_pos


# Emit signals when crossing chunk/region boundaries
func _update_current_chunk() -> void:
	var new_chunk = Vector2i(int(floor(global_position.x / GlobalSettings.CHUNK_SIZE)), int(floor(global_position.y / GlobalSettings.CHUNK_SIZE)))
	if new_chunk != _current_chunk:
		_current_chunk = new_chunk
		SignalBus.emit_signal("player_chunk_changed", _current_chunk)


# need to move all the input handling to this func at some point
func _input(event: InputEvent) -> void:
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom.x *= 1 + zoom_amount
			_camera.zoom.y *= 1 + zoom_amount
			# Make sure the camera zoom doesn't zoom too far
			if _camera.zoom > maximum_zoom:
				_camera.zoom = maximum_zoom
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom.x *= 1 - zoom_amount
			_camera.zoom.y *= 1 - zoom_amount
			# Make sure the zoom isn't 0
			if _camera.zoom < minimum_zoom:
				_camera.zoom = minimum_zoom
	# Get the input direction and handle the movement/deceleration.
	if Input.is_action_pressed("move_left"):
		velocity.x = - speed
	elif Input.is_action_pressed("move_right"):
		velocity.x = speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	if Input.is_action_pressed("move_up"):
		velocity.y = - speed
	elif Input.is_action_pressed("move_down"):
		velocity.y = speed
	else:
		velocity.y = move_toward(velocity.y, 0, speed)