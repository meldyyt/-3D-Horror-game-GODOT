class_name EventDelay
extends HorrorEvent

@export var delay_time: float = 1.0

func _run_event():
	if delay_time > 0:
		await get_tree().create_timer(delay_time).timeout
	finish()
