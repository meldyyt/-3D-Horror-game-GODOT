class_name HauntedToy
extends StaticBody3D

@export var prompt: String = "Осмотреть предмет"
@export_multiline var inspect_message: String = "«Старая детская игрушка со следами копоти... Почему она пахнет дымом?»"
@export var inspect_sound: AudioStream = preload("res://assets/audio/impacts/wood_tap.ogg")

var _has_inspected: bool = false

func _ready() -> void:
	add_to_group("loop_haunted_objects")

func get_interaction_prompt(_player: Node = null) -> String:
	return prompt

func can_interact(_player: Node = null) -> bool:
	return visible

func interact(player: Node) -> void:
	if inspect_sound:
		AudioManager.play_sfx(inspect_sound, -4.0)
	
	if player and player.has_method("show_notification"):
		player.show_notification(inspect_message, 5.0)
	
	if not _has_inspected:
		_has_inspected = true
		# Subtle light flicker on first inspection
		var lights = get_tree().get_nodes_in_group("corridor_lights")
		for l in lights:
			if l is FlickeringLight:
				l._perform_flicker()
