class_name PlayerLook
extends Node3D

@export var mouse_sensitivity: float = 0.0025
@export var min_pitch_deg: float = -85.0
@export var max_pitch_deg: float = 85.0

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D

var _pitch: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if player and player.has_method("is_inventory_open") and player.is_inventory_open():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rot_x = -event.relative.x * mouse_sensitivity
		if player:
			player.rotate_y(rot_x)
		else:
			rotate_y(rot_x)
		
		_pitch = clamp(
			_pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)
		rotation.x = _pitch

	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	elif event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
