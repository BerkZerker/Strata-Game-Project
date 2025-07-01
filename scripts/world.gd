extends Node2D

var is_panning: bool = false
var last_mouse_position: Vector2
var target_pos: Vector2 = Vector2.ZERO

@onready var camera: Camera2D = $Camera2D

func _input(event: InputEvent) -> void:

	# Crapy camera controlls
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
		is_panning = true
		last_mouse_position = get_global_mouse_position()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		is_panning = false
	elif event is InputEventMouseMotion and is_panning:
		var current_mouse_position = get_global_mouse_position()
		var delta = current_mouse_position - last_mouse_position
		camera.position -= delta
		last_mouse_position = current_mouse_position
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		camera.zoom *= 1.05
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		camera.zoom *= 0.95
