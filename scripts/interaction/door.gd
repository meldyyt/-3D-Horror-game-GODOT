class_name Door
extends Node3D

enum State {
	CLOSED,
	OPEN,
	LOCKED
}

signal door_state_changed(new_state: State)
signal door_opened()
signal door_closed()
signal door_locked()
signal door_unlocked()
signal horror_triggered()

@export var current_state: State = State.CLOSED
@export var is_locked: bool = false
@export var required_key_id: String = ""
@export var consume_key_on_unlock: bool = false

@export_group("Door Movement")
@export var open_angle_degrees: float = 90.0
@export var open_duration: float = 0.8
@export var auto_close_delay: float = 0.0

@export_group("Prompts")
@export var open_prompt: String = "Открыть дверь"
@export var close_prompt: String = "Закрыть дверь"
@export var locked_prompt: String = "Заперто"
@export var unlock_prompt: String = "Отпереть ключом"

@export_group("Audio")
@export var open_sound: AudioStream = preload("res://assets/audio/door_open.wav")
@export var close_sound: AudioStream = preload("res://assets/audio/door_close.wav")
@export var locked_sound: AudioStream = preload("res://assets/audio/door_locked.wav")
@export var unlock_sound: AudioStream = preload("res://assets/audio/door_unlock.wav")

@onready var hinge: Node3D = $Hinge
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var leaf_collision: CollisionShape3D = get_node_or_null("Hinge/DoorLeaf/CollisionShape3D")

var _tween: Tween
var _is_animating: bool = false
var _closed_rotation_y: float = 0.0

func _ready() -> void:
	if hinge:
		_closed_rotation_y = hinge.rotation.y
	
	if is_locked:
		current_state = State.LOCKED
	elif current_state == State.LOCKED:
		is_locked = true
	
	if current_state == State.OPEN and hinge:
		hinge.rotation.y = _closed_rotation_y + deg_to_rad(open_angle_degrees)
		if leaf_collision:
			leaf_collision.set_deferred("disabled", true)
	else:
		if leaf_collision:
			leaf_collision.set_deferred("disabled", false)

func get_interaction_prompt(_player: Node = null) -> String:
	if current_state == State.LOCKED or is_locked:
		if not required_key_id.is_empty() and InventoryManager.has_item(required_key_id):
			return unlock_prompt
		return locked_prompt
	elif current_state == State.OPEN:
		return close_prompt
	else:
		return open_prompt

func can_interact(_player: Node = null) -> bool:
	return not _is_animating

func interact(player: Node) -> void:
	if _is_animating:
		return
	
	if current_state == State.LOCKED or is_locked:
		_handle_locked_interaction(player)
		return
	
	if current_state == State.CLOSED:
		open()
	else:
		close()

func _handle_locked_interaction(player: Node) -> void:
	if not required_key_id.is_empty() and InventoryManager.has_item(required_key_id):
		unlock()
		if consume_key_on_unlock:
			InventoryManager.remove_item(required_key_id)
		if player and player.has_method("show_notification"):
			player.show_notification("Дверь открыта ключом")
		open()
	else:
		_play_sound(locked_sound)
		door_locked.emit()
		if player and player.has_method("show_notification"):
			player.show_notification("Заперто. Требуется ключ.")

func open() -> void:
	if _is_animating or current_state == State.OPEN or is_locked:
		return
	
	_is_animating = true
	_play_sound(open_sound)
	
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var target_y = _closed_rotation_y + deg_to_rad(open_angle_degrees)
	_tween.tween_property(hinge, "rotation:y", target_y, open_duration)
	_tween.finished.connect(func():
		_is_animating = false
		current_state = State.OPEN
		if leaf_collision:
			leaf_collision.set_deferred("disabled", true)
		door_opened.emit()
		door_state_changed.emit(current_state)
		if auto_close_delay > 0.0:
			get_tree().create_timer(auto_close_delay).timeout.connect(close)
	)

func close() -> void:
	if _is_animating or current_state == State.CLOSED:
		return
	
	_is_animating = true
	_play_sound(close_sound)
	if leaf_collision:
		leaf_collision.set_deferred("disabled", false)
	
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(hinge, "rotation:y", _closed_rotation_y, open_duration * 0.9)
	_tween.finished.connect(func():
		_is_animating = false
		current_state = State.CLOSED
		door_closed.emit()
		door_state_changed.emit(current_state)
	)

func lock() -> void:
	is_locked = true
	current_state = State.LOCKED
	door_locked.emit()
	door_state_changed.emit(current_state)

func unlock() -> void:
	is_locked = false
	current_state = State.CLOSED
	_play_sound(unlock_sound)
	door_unlocked.emit()
	door_state_changed.emit(current_state)

# Horror event controls
func force_open(speed_scale: float = 1.0) -> void:
	if is_locked:
		unlock()
	open_duration /= max(0.1, speed_scale)
	open()

func force_close(speed_scale: float = 2.0) -> void:
	open_duration /= max(0.1, speed_scale)
	close()

func slam_shut() -> void:
	close()
	lock()
	horror_triggered.emit()

func _play_sound(stream: AudioStream) -> void:
	if stream and audio_player:
		audio_player.stream = stream
		audio_player.play()
