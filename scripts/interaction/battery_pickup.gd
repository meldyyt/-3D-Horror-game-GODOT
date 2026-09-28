class_name BatteryPickup
extends StaticBody3D

signal picked_up(charge: float)

@export var charge_amount: float = 50.0
@export var pickup_sound: AudioStream = preload("res://assets/audio/battery_pickup.wav")
@export var is_interactable: bool = true

@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")
@onready var mesh_node: Node3D = $MeshContainer

var _anim_time: float = 0.0

func _process(delta: float) -> void:
	# Subtle hover and rotation
	_anim_time += delta
	if mesh_node:
		mesh_node.position.y = sin(_anim_time * 2.5) * 0.02
		mesh_node.rotate_y(deg_to_rad(45.0) * delta)

func get_interaction_prompt(_player: Node = null) -> String:
	return "Взять батарейку (+%d%%)" % int(charge_amount)

func can_interact(_player: Node = null) -> bool:
	return is_interactable

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	
	if player and "flashlight" in player and player.flashlight:
		player.flashlight.add_battery(charge_amount)
		if player.has_method("show_notification"):
			player.show_notification("Батарейка заряжена: +%d%%" % int(charge_amount), 3.0)
	
	picked_up.emit(charge_amount)
	
	if audio_player and pickup_sound:
		audio_player.stream = pickup_sound
		audio_player.reparent(get_parent())
		audio_player.play()
		audio_player.finished.connect(audio_player.queue_free)
	elif pickup_sound and AudioManager:
		AudioManager.play_sfx(pickup_sound, -2.0)
	
	queue_free()
