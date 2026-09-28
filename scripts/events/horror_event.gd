class_name HorrorEvent
extends Node

signal event_finished

@export var is_one_shot: bool = true
@export var delay_before_start: float = 0.0

var has_triggered: bool = false

func execute():
	if has_triggered and is_one_shot:
		return
	has_triggered = true
	
	if delay_before_start > 0:
		await get_tree().create_timer(delay_before_start).timeout
		
	_run_event()

# Override this in subclasses
func _run_event():
	finish()

func finish():
	event_finished.emit()
