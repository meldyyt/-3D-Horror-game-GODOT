class_name LoopTrigger
extends Area3D

signal loop_triggered(loop_number: int)

@export var is_active: bool = true
@export var teleport_target: Node3D
@export var custom_teleport_pos: Vector3 = Vector3.ZERO
@export var use_custom_pos: bool = false
@export var transition_sound: AudioStream = preload("res://assets/audio/impacts/concrete_tap.ogg")
@export var cooldown_seconds: float = 2.0

var _is_cooling_down: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player is on collision layer 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not is_active or _is_cooling_down:
		return
	
	if body.is_in_group("player"):
		_trigger_loop_wrap(body)

func _trigger_loop_wrap(player: Node3D) -> void:
	_is_cooling_down = true
	
	if transition_sound:
		AudioManager.play_sfx(transition_sound, -4.0)
	
	ScreenFader.blink(0.12, 0.35, func():
		var target_pos = teleport_target.global_position if teleport_target else custom_teleport_pos
		if use_custom_pos:
			target_pos = custom_teleport_pos
		
		player.global_position = target_pos
		
		LoopManager.advance_loop()
		loop_triggered.emit(LoopManager.current_loop)
	)
	
	get_tree().create_timer(cooldown_seconds).timeout.connect(func():
		_is_cooling_down = false
	)
