class_name EventTrigger
extends Area3D

@export var target_event: Node # Should be a HorrorEvent
@export var required_loop: int = -1 # -1 means any loop
@export var trigger_once: bool = true

var has_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	collision_mask = 2 # Usually player mask, but we'll check group anyway

func _on_body_entered(body):
	if trigger_once and has_triggered:
		return
		
	if not body.is_in_group("player"):
		return
		
	# Assuming LoopManager is an autoload
	if required_loop != -1 and LoopManager.current_loop_index != required_loop:
		return
		
	has_triggered = true
	
	if target_event and target_event.has_method("execute"):
		target_event.execute()
