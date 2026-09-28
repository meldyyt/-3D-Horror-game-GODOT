class_name EnemyAI
extends CharacterBody3D

enum State {
	IDLE,
	PATROL,
	INVESTIGATE,
	CHASE,
	ATTACK
}

signal state_changed(new_state: State)
signal player_caught()

@export_group("Speeds")
@export var patrol_speed: float = 1.3
@export var chase_speed: float = 2.8
@export var turn_speed: float = 5.0
@export var catch_distance: float = 1.35

@export_group("Vision & Audio")
@export var vision_distance: float = 14.0
@export var vision_angle_deg: float = 75.0
@export var eye_height: float = 1.7
@export var lose_sight_time: float = 3.0
@export var growl_sound: AudioStream = preload("res://assets/audio/monster_growl.wav")

@export_group("Patrol & Search")
@export var patrol_wait_time: float = 2.0
@export var search_duration: float = 5.0
@export var waypoints: Array[Vector3] = [
	Vector3(0, 0, -8.0),
	Vector3(0, 0, -3.0),
	Vector3(1.8, 0, -1.0),
	Vector3(0, 0, 3.0)
]

@onready var visual_mesh: Node3D = $Visuals
@onready var groan_audio: AudioStreamPlayer3D = get_node_or_null("GroanAudio")

var current_state: State = State.PATROL
var current_target_pos: Vector3 = Vector3.ZERO
var last_known_player_pos: Vector3 = Vector3.ZERO
var _current_waypoint_idx: int = 0
var _wait_timer: float = 0.0
var _search_timer: float = 0.0
var _time_lost_player: float = 0.0
var _has_caught: bool = false
var _walk_anim_time: float = 0.0

var player: Player = null

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as Player
	if not waypoints.is_empty():
		current_target_pos = waypoints[0]

func _physics_process(delta: float) -> void:
	if _has_caught or current_state == State.ATTACK:
		velocity = Vector3.ZERO
		return
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Player
	
	# Check if player is caught
	if _check_catch_player():
		return
	
	# Perception checks
	_update_perception(delta)
	
	# State update
	match current_state:
		State.IDLE:
			_update_idle(delta)
		State.PATROL:
			_update_patrol(delta)
		State.INVESTIGATE:
			_update_investigate(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			velocity = Vector3.ZERO
	
	move_and_slide()
	_update_procedural_walk(delta)

func _update_perception(delta: float) -> void:
	if player == null or current_state == State.ATTACK:
		return
	
	var can_see = _can_see_player()
	if can_see:
		last_known_player_pos = player.global_position
		_time_lost_player = 0.0
		if current_state != State.CHASE:
			_change_state(State.CHASE)
	else:
		if current_state == State.CHASE:
			_time_lost_player += delta
			if _time_lost_player >= lose_sight_time:
				_change_state(State.INVESTIGATE)
	
	# Noise hearing (investigates sound source)
	if current_state == State.PATROL or current_state == State.IDLE:
		if player.has_method("get_noise_level"):
			var noise = player.get_noise_level()
			var dist = global_position.distance_to(player.global_position)
			if noise > 1.8 and dist < 15.0: # Loud sprint heard
				last_known_player_pos = player.global_position
				_change_state(State.INVESTIGATE)
			elif noise > 0.6 and dist < 5.0: # Normal footsteps nearby
				last_known_player_pos = player.global_position
				_change_state(State.INVESTIGATE)

func _can_see_player() -> bool:
	if player == null:
		return false
	
	var my_eye = global_position + Vector3(0, eye_height, 0)
	var player_head = player.global_position + Vector3(0, 1.5, 0)
	var offset = player_head - my_eye
	var dist = offset.length()
	
	var max_dist = vision_distance
	if player.has_method("get_visibility_factor"):
		max_dist *= player.get_visibility_factor()
	
	if dist > max_dist:
		return false
	
	# Check field of view angle
	var forward = -global_transform.basis.z.normalized()
	var to_player = offset.normalized()
	var angle = rad_to_deg(forward.angle_to(to_player))
	if angle > vision_angle_deg * 0.5:
		return false
	
	# Line of sight physics raycast
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(my_eye, player_head)
	query.exclude = [self]
	query.collision_mask = 1 # Collide with environment / walls
	
	var result = space_state.intersect_ray(query)
	return result.is_empty() # Unobstructed view

func _update_idle(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
	
	_wait_timer -= delta
	if _wait_timer <= 0.0:
		_choose_next_waypoint()
		_change_state(State.PATROL)

func _update_patrol(delta: float) -> void:
	var flat_dist = Vector2(current_target_pos.x - global_position.x, current_target_pos.z - global_position.z).length()
	if flat_dist <= 0.6:
		_wait_timer = patrol_wait_time
		_change_state(State.IDLE)
		return
	
	_move_towards(current_target_pos, patrol_speed, delta)

func _update_investigate(delta: float) -> void:
	_search_timer += delta
	var flat_dist = Vector2(last_known_player_pos.x - global_position.x, last_known_player_pos.z - global_position.z).length()
	
	if flat_dist > 0.8:
		_move_towards(last_known_player_pos, patrol_speed * 1.15, delta)
	else:
		# Arrived at noise location, look around
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		rotate_y(deg_to_rad(45.0) * delta)
	
	if _search_timer >= search_duration:
		_choose_next_waypoint()
		_change_state(State.PATROL)

func _update_chase(delta: float) -> void:
	if player:
		current_target_pos = player.global_position
	_move_towards(current_target_pos, chase_speed, delta)

func _move_towards(target: Vector3, speed: float, delta: float) -> void:
	var dir = target - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	
	# Turn toward movement direction
	var target_yaw = atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, turn_speed * delta)

func _choose_next_waypoint() -> void:
	if waypoints.is_empty():
		return
	_current_waypoint_idx = (_current_waypoint_idx + 1) % waypoints.size()
	current_target_pos = waypoints[_current_waypoint_idx]

func _change_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	
	if new_state == State.CHASE:
		if growl_sound and AudioManager:
			AudioManager.play_sfx(growl_sound, 2.0)
		elif groan_audio and not groan_audio.playing:
			groan_audio.play()
	elif new_state == State.INVESTIGATE:
		_search_timer = 0.0

func _check_catch_player() -> bool:
	if _has_caught or player == null or current_state == State.ATTACK:
		return _has_caught
	
	var flat_dist = Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length()
	if flat_dist <= catch_distance:
		_change_state(State.ATTACK)
		_catch_player()
		return true
	return false

func _catch_player() -> void:
	_has_caught = true
	velocity = Vector3.ZERO
	player_caught.emit()
	
	# Face directly at player
	var dir = (player.global_position - global_position).normalized()
	rotation.y = atan2(-dir.x, -dir.z)
	
	if player and player.has_method("start_jumpscare"):
		player.start_jumpscare(self)

func _update_procedural_walk(delta: float) -> void:
	if visual_mesh == null:
		return
	
	var is_moving = Vector2(velocity.x, velocity.z).length() > 0.1
	if is_moving:
		_walk_anim_time += delta * (11.0 if current_state == State.CHASE else 6.0)
		visual_mesh.position.y = abs(sin(_walk_anim_time)) * 0.08
		visual_mesh.rotation.z = sin(_walk_anim_time * 0.5) * 0.05
	else:
		visual_mesh.position.y = lerp(visual_mesh.position.y, 0.0, 5.0 * delta)
		visual_mesh.rotation.z = lerp(visual_mesh.rotation.z, 0.0, 5.0 * delta)
