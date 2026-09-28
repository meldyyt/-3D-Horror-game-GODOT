class_name EventSequence
extends HorrorEvent

func _run_event():
	var children = get_children()
	for child in children:
		if child is HorrorEvent:
			child.execute()
			await child.event_finished
	
	finish()
