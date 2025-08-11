extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -250.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D


# I know this code is a mess I just don't care
# - past me
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Move the player.
	move_and_slide()


# need to move all the input handling to this func at some point
func _input(event: InputEvent) -> void:
	# Handle zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom.x += 0.1
			camera.zoom.y += 0.1

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom.x -= 0.1
			camera.zoom.y -= 0.1

	# Handle jump.
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	if Input.is_key_pressed(KEY_A):
		velocity.x = - SPEED

	elif Input.is_key_pressed(KEY_D):
		velocity.x = SPEED

	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
