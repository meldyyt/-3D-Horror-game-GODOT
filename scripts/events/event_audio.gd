class_name EventAudio
extends HorrorEvent

@export var audio_player: AudioStreamPlayer3D
@export var wait_for_completion: bool = false

func _run_event():
	if audio_player:
		audio_player.play()
		if wait_for_completion:
			await audio_player.finished
			
	finish()
