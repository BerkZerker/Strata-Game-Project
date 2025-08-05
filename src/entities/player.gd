extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -600.0

@onready var sprite: Sprite2D = $Sprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	if Input.is_key_pressed(KEY_A):
		velocity.x = - SPEED
		sprite.position.x = -3
		sprite.scale.x = 0.61
	elif Input.is_key_pressed(KEY_D):
		velocity.x = SPEED
		sprite.position.x = 3
		sprite.scale.x = -0.61
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
