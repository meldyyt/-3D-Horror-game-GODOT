class_name Silhouette
extends Node3D

signal vanished()

@export var vanish_distance: float = 4.5
@export var vanish_sound: AudioStream = preload("res://assets/audio/impacts/wood_crash.ogg")

@onready var notifier: VisibleOnScreenNotifier3D = get_node_or_null("VisibleOnScreenNotifier3D")

var _has_been_seen: bool = false
var _is_vanished: bool = false
var _seen_timer: float = 0.0

func _ready() -> void:
	add_to_group("loop_silhouette")
	if notifier:
		notifier.screen_entered.connect(_on_screen_entered)

func _process(delta: float) -> void:
	if not visible or _is_vanished:
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= vanish_distance:
			vanish()
			return
	
	if _has_been_seen:
		_seen_timer += delta
		# After looking at it for ~1.5 seconds, it vanishes with a sudden light flicker
		if _seen_timer >= 1.5:
			vanish()

func _on_screen_entered() -> void:
	if not _has_been_seen and visible:
		_has_been_seen = true

func vanish() -> void:
	if _is_vanished:
		return
	_is_vanished = true
	
	if vanish_sound:
		AudioManager.play_sfx(vanish_sound, -2.0)
	
	# Flicker player's flashlight if nearby
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Head/Camera3D/Flashlight"):
		var fl = player.get_node("Head/Camera3D/Flashlight") as Flashlight
		if fl:
			fl.trigger_flicker(0.8, 0.0)
	
	# Quick blink screen transition and disappear
	ScreenFader.blink(0.08, 0.25, func():
		visible = false
		vanished.emit()
	)
