class_name Player extends CharacterBody2D

@export var SPEED: int = 100
@export var JUMP_VELOCITY: int = -250
@export var STEP_HEIGHT: int = 8
@export var COYOTE_TIME: float = 0.2
@export var ZOOM_AMOUNT: float = 0.1
@export var MINIMUM_ZOOM: Vector2 = Vector2(0.001, 0.001)
@export var MAXIMUM_ZOOM: Vector2 = Vector2(100, 100)

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D
@onready var left_shapecast: ShapeCast2D = $CollisionShape2D/ShapeCastLeft
@onready var right_shapecast: ShapeCast2D = $CollisionShape2D/ShapeCastRight
@onready var coyote_timer: Timer = $CoyoteTimer

var was_on_floor: bool = false
var current_chunk: Vector2i = Vector2i.ZERO

func _ready() -> void:
	coyote_timer.wait_time = COYOTE_TIME
	#current_chunk = Vector2i(floor(position.x / GlobalSettings.CHUNK_SIZE), floor(position.y / GlobalSettings.CHUNK_SIZE)) # Calculate initial chunk position


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		# Start coyote timer when walking off a ledge
		if was_on_floor and coyote_timer.is_stopped():
			coyote_timer.start()
	else:
		# Reset coyote timer when on floor
		coyote_timer.stop()
		
	was_on_floor = is_on_floor() # Update floor state

	# Handle stepping up slopes
	handle_step_up()

	# Move the player.
	move_and_slide()

	if current_chunk != Vector2i(floor(position.x / GlobalSettings.CHUNK_SIZE), floor(position.y / GlobalSettings.CHUNK_SIZE)):
		current_chunk = Vector2i(floor(position.x / GlobalSettings.CHUNK_SIZE), floor(position.y / GlobalSettings.CHUNK_SIZE))
		SignalBus.emit_signal("player_chunk_changed", current_chunk)
	
	# Just write my own collision logic since this is such a specialized geometry
	# I can reuse much of what I already have, such as coyote jump, and the wall step but 
	# I need to manually move the player and handle collisions if they occur.
	
	#var data = move_and_collide(velocity)


func handle_step_up() -> void:
	# Only check for steps if we're moving and on the floor
	if velocity.x != 0 and is_on_floor():
		var check_shapecast = right_shapecast if velocity.x > 0 else left_shapecast

		# Check if there's an obstacle in front
		if check_shapecast.is_colliding():
			var original_pos = check_shapecast.position

			for i in range(STEP_HEIGHT):
				check_shapecast.position.y -= 1
				check_shapecast.force_shapecast_update()

				if not check_shapecast.is_colliding():
					# We can step up! Move the player up
					was_on_floor = true
					coyote_timer.stop()
					position.y -= i + 1
					break

			check_shapecast.position = original_pos


# need to move all the input handling to this func at some point
func _input(event: InputEvent) -> void:
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom.x *= 1 + ZOOM_AMOUNT
			camera.zoom.y *= 1 + ZOOM_AMOUNT
			# Make sure the camera zoom doesn't zoom too far
			if camera.zoom > MAXIMUM_ZOOM:
				camera.zoom = MAXIMUM_ZOOM

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom.x *= 1 - ZOOM_AMOUNT
			camera.zoom.y *= 1 - ZOOM_AMOUNT
			# Make sure the zoom isn't 0
			if camera.zoom < MINIMUM_ZOOM:
				camera.zoom = MINIMUM_ZOOM

	# Handle jump
	if Input.is_action_just_pressed("jump") and (is_on_floor() or not coyote_timer.is_stopped()):
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()

	# Get the input direction and handle the movement/deceleration.
	if Input.is_action_pressed("move_left"):
		velocity.x = - SPEED
	elif Input.is_action_pressed("move_right"):
		velocity.x = SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
