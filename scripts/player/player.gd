class_name Player
extends CharacterBody3D

signal state_changed(is_sprinting: bool, is_crouching: bool)
signal stamina_changed(current: float, max_val: float)

@export_group("Speeds")
@export var walk_speed: float = 3.0
@export var sprint_speed: float = 5.2
@export var crouch_speed: float = 1.8
@export var acceleration: float = 10.0
@export var deceleration: float = 12.0

@export_group("Stamina")
@export var max_stamina: float = 100.0
@export var sprint_stamina_cost: float = 22.0
@export var stamina_recovery_walk: float = 14.0
@export var stamina_recovery_idle: float = 24.0
@export var stamina_recovery_crouch: float = 34.0

@export_group("Crouch Settings")
@export var stand_height: float = 1.8
@export var crouch_height: float = 1.1
@export var stand_head_y: float = 1.65
@export var crouch_head_y: float = 1.0
@export var crouch_transition_speed: float = 10.0

@export_group("Footsteps")
@export var footstep_sounds: Array[AudioStream] = [
	preload("res://assets/audio/footsteps/step2.ogg"),
	preload("res://assets/audio/footsteps/step3.ogg"),
	preload("res://assets/audio/footsteps/step6.ogg")
]
@export var walk_step_interval: float = 0.52
@export var sprint_step_interval: float = 0.34
@export var crouch_step_interval: float = 0.78


@export_group("Head Bobbing")
@export var bob_enabled: bool = true
@export var bob_walk_speed: float = 10.0
@export var bob_walk_amount: float = 0.035
@export var bob_sprint_speed: float = 14.0
@export var bob_sprint_amount: float = 0.055
@export var bob_idle_speed: float = 2.0
@export var bob_idle_amount: float = 0.008

@export_group("Physics")
@export var gravity: float = 9.8

@onready var head: Node3D = $Head
@onready var camera: Camera3D = get_node_or_null("Head/Camera3D") as Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_check: RayCast3D = get_node_or_null("CeilingCheck")
@onready var flashlight: Flashlight = get_node_or_null("Head/Camera3D/Flashlight") as Flashlight
@onready var footstep_audio: AudioStreamPlayer3D = get_node_or_null("FootstepAudio")
@onready var interaction_ui: InteractionUI = get_node_or_null("InteractionUI")
@onready var inventory_ui: InventoryUI = get_node_or_null("InventoryUI") as InventoryUI
@onready var breathing_audio: AudioStreamPlayer = get_node_or_null("BreathingAudio")
@onready var heartbeat_audio: AudioStreamPlayer = get_node_or_null("HeartbeatAudio")

var is_sprinting: bool = false
var is_crouching: bool = false
var is_in_jumpscare: bool = false
var is_exhausted: bool = false
var stamina: float = 100.0
var fear_level: float = 0.0
var current_speed: float = 0.0
var _capsule_shape: CapsuleShape3D
var _step_timer: float = 0.0
var _bob_time: float = 0.0
var _bob_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		# Duplicate shape to not affect other instances
		collision_shape.shape = collision_shape.shape.duplicate()
		_capsule_shape = collision_shape.shape as CapsuleShape3D

	if interaction_ui:
		stamina_changed.connect(func(curr: float, max_val: float):
			interaction_ui.update_stamina(curr, max_val, is_exhausted)
		)
		if flashlight:
			flashlight.battery_changed.connect(func(curr: float, max_val: float):
				interaction_ui.update_battery(curr, max_val)
			)
			flashlight.state_changed.connect(func(is_on: bool):
				interaction_ui.set_flashlight_active(is_on)
			)
			interaction_ui.update_battery(flashlight.battery, flashlight.max_battery)
			interaction_ui.set_flashlight_active(flashlight.is_on)

func _physics_process(delta: float) -> void:
	if is_in_jumpscare:
		return
	_handle_gravity(delta)
	_handle_crouch(delta)
	_handle_stamina(delta)
	_handle_movement(delta)
	_handle_footsteps(delta)
	_handle_head_bob(delta)
	_handle_fear_and_heartbeat(delta)
	_handle_breathing(delta)


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0

func _handle_crouch(delta: float) -> void:
	var wants_crouch = Input.is_action_pressed("crouch")
	
	# If currently crouching and wanting to stand, check if ceiling blocks us
	if not wants_crouch and is_crouching:
		if ceiling_check and ceiling_check.is_colliding():
			wants_crouch = true
	
	is_crouching = wants_crouch
	
	var target_head_y = crouch_head_y if is_crouching else stand_head_y
	var target_shape_height = crouch_height if is_crouching else stand_height
	
	if head:
		head.position.y = lerp(head.position.y, target_head_y, crouch_transition_speed * delta)
	
	if _capsule_shape:
		_capsule_shape.height = lerp(_capsule_shape.height, target_shape_height, crouch_transition_speed * delta)
		if collision_shape:
			collision_shape.position.y = _capsule_shape.height * 0.5

func _handle_movement(delta: float) -> void:
	if is_inventory_open():
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
		current_speed = Vector2(velocity.x, velocity.z).length()
		move_and_slide()
		return

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Fallback if action didn't register (e.g. non-Latin OS keyboard layout)
	if input_dir == Vector2.ZERO:
		var x = 0.0
		var y = 0.0
		if Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			y += 1.0
		if Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			x += 1.0
		if x != 0.0 or y != 0.0:
			input_dir = Vector2(x, y).normalized()
	
	var move_direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Determine speed
	var target_speed = walk_speed
	var wants_sprint = Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_SHIFT)
	
	if is_crouching:
		target_speed = crouch_speed
		is_sprinting = false
	elif wants_sprint and not is_exhausted and stamina > 5.0 and input_dir.y < 0: # Sprint forward only
		target_speed = sprint_speed
		is_sprinting = true
	else:
		target_speed = walk_speed
		is_sprinting = false
	
	var accel = acceleration if move_direction != Vector3.ZERO else deceleration
	var target_velocity_x = move_direction.x * target_speed
	var target_velocity_z = move_direction.z * target_speed
	
	velocity.x = lerp(velocity.x, target_velocity_x, accel * delta)
	velocity.z = lerp(velocity.z, target_velocity_z, accel * delta)
	
	current_speed = Vector2(velocity.x, velocity.z).length()
	move_and_slide()


func _handle_footsteps(delta: float) -> void:
	if not is_on_floor() or current_speed < 0.2:
		_step_timer = 0.0
		return
	
	var interval = walk_step_interval
	var pitch = randf_range(0.95, 1.05)
	var volume_db = -8.0
	
	if is_crouching:
		interval = crouch_step_interval
		pitch = randf_range(0.8, 0.9)
		volume_db = -14.0
	elif is_sprinting:
		interval = sprint_step_interval
		pitch = randf_range(1.1, 1.25)
		volume_db = -4.0
	
	_step_timer += delta
	if _step_timer >= interval:
		_step_timer = 0.0
		_play_footstep(pitch, volume_db)

func _play_footstep(pitch: float, volume_db: float) -> void:
	if footstep_audio and not footstep_sounds.is_empty():
		var stream = footstep_sounds.pick_random()
		if stream:
			footstep_audio.stream = stream
			footstep_audio.pitch_scale = pitch
			footstep_audio.volume_db = volume_db
			footstep_audio.play()



func show_notification(text: String, duration: float = 3.0) -> void:
	if interaction_ui:
		interaction_ui.show_notification(text, duration)

func _handle_stamina(delta: float) -> void:
	if is_sprinting and current_speed > 1.0:
		stamina = max(0.0, stamina - sprint_stamina_cost * delta)
		if stamina <= 0.0:
			stamina = 0.0
			is_exhausted = true
			is_sprinting = false
	else:
		var recovery_rate = stamina_recovery_crouch if is_crouching else (stamina_recovery_idle if current_speed < 0.2 else stamina_recovery_walk)
		stamina = min(max_stamina, stamina + recovery_rate * delta)
		if is_exhausted and stamina >= 25.0:
			is_exhausted = false
	
	stamina_changed.emit(stamina, max_stamina)

func _handle_fear_and_heartbeat(delta: float) -> void:
	var target_fear = 0.0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node3D and enemy.visible and enemy.is_inside_tree():
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= 15.0:
				var proximity = clamp(1.0 - (dist / 15.0), 0.0, 1.0)
				if "current_state" in enemy and str(enemy.current_state) == "2": # CHASE state
					proximity = 1.0
				target_fear = max(target_fear, proximity)
	
	fear_level = lerp(fear_level, target_fear, 3.0 * delta)
	
	if heartbeat_audio:
		if fear_level > 0.08:
			if not heartbeat_audio.playing:
				heartbeat_audio.play()
			heartbeat_audio.volume_db = lerp(-22.0, -1.0, fear_level)
			heartbeat_audio.pitch_scale = lerp(0.85, 1.35, fear_level)
		else:
			if heartbeat_audio.playing:
				heartbeat_audio.volume_db = lerp(heartbeat_audio.volume_db, -45.0, 4.0 * delta)
				if heartbeat_audio.volume_db < -40.0:
					heartbeat_audio.stop()

func _handle_breathing(delta: float) -> void:
	if breathing_audio:
		if is_exhausted or stamina < 30.0:
			if not breathing_audio.playing:
				breathing_audio.play()
			var intensity = 1.0 - (stamina / 30.0)
			breathing_audio.volume_db = lerp(-14.0, -2.0, intensity)
			breathing_audio.pitch_scale = lerp(0.9, 1.15, intensity)
		else:
			if breathing_audio.playing:
				breathing_audio.volume_db = lerp(breathing_audio.volume_db, -45.0, 3.0 * delta)
				if breathing_audio.volume_db < -40.0:
					breathing_audio.stop()

func get_visibility_factor() -> float:
	var factor = 1.0
	if is_crouching:
		factor *= 0.25 # 75% stealth bonus when crouching!
	if flashlight and flashlight.is_on:
		factor *= 2.2 # Flashlight beam makes player very noticeable
	else:
		factor *= 0.4 # Darkness conceals player
	return factor

func get_noise_level() -> float:
	if current_speed < 0.1:
		return 0.0
	if is_crouching:
		return 0.15
	if is_sprinting:
		return 2.8
	return 0.75

func is_inventory_open() -> bool:
	return inventory_ui != null and inventory_ui.is_open

func _handle_head_bob(delta: float) -> void:
	if not bob_enabled or camera == null:
		return
	
	if is_on_floor() and current_speed > 0.2:
		var freq = bob_sprint_speed if is_sprinting else bob_walk_speed
		var amp = bob_sprint_amount if is_sprinting else bob_walk_amount
		_bob_time += delta * freq
		_bob_offset.y = sin(_bob_time) * amp
		_bob_offset.x = cos(_bob_time * 0.5) * amp * 0.6
	else:
		_bob_time += delta * bob_idle_speed
		_bob_offset.y = lerp(_bob_offset.y, sin(_bob_time) * bob_idle_amount, 6.0 * delta)
		_bob_offset.x = lerp(_bob_offset.x, 0.0, 6.0 * delta)
	
	camera.position.x = _bob_offset.x
	camera.position.y = _bob_offset.y

func start_jumpscare(enemy: Node3D) -> void:
	if is_in_jumpscare:
		return
	is_in_jumpscare = true
	velocity = Vector3.ZERO
	
	var jumpscare_sound = load("res://assets/audio/jumpscare.mp3") as AudioStream
	if jumpscare_sound and AudioManager:
		AudioManager.play_sfx(jumpscare_sound, 4.0)
	
	if enemy and head and camera:
		var dir = (enemy.global_position - head.global_position).normalized()
		var target_yaw = atan2(-dir.x, -dir.z)
		global_rotation.y = target_yaw
		camera.rotation.x = deg_to_rad(-10.0)
	
	ScreenFader.blink(0.4, 0.8, func():
		if LoopManager:
			LoopManager.restart_loops()
		show_notification("ТЫ ПОГИБ... ПЕТЛЯ ПЕРЕЗАПУЩЕНА.", 4.0)
		is_in_jumpscare = false
	)
