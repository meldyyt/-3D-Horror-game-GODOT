class_name PlayerInteraction
extends RayCast3D

@export var interaction_ui: InteractionUI
@export var player: CharacterBody3D

var _current_target: Object = null

func _ready() -> void:
	if player == null:
		player = owner as CharacterBody3D
	
	if interaction_ui == null and player != null:
		interaction_ui = player.get_node_or_null("InteractionUI") as InteractionUI

func _process(_delta: float) -> void:
	_check_interaction()

func _check_interaction() -> void:
	var target = null
	
	if is_colliding():
		var collider = get_collider()
		target = _find_interactable(collider)
	
	if target != null and _can_interact_with(target):
		_current_target = target
		var prompt_text = "[E] Взаимодействовать"
		if target.has_method("get_interaction_prompt"):
			var p = target.get_interaction_prompt(player)
			if not p.is_empty():
				prompt_text = "[E] " + p
		
		if interaction_ui:
			interaction_ui.show_prompt(prompt_text)
		
		if Input.is_action_just_pressed("interact"):
			target.interact(player)
	else:
		if _current_target != null:
			_current_target = null
			if interaction_ui:
				interaction_ui.hide_prompt()

func _can_interact_with(target: Object) -> bool:
	if target == null:
		return false
	if target.has_method("can_interact"):
		return target.can_interact(player)
	return true

func _find_interactable(collider: Object) -> Object:
	if collider == null:
		return null
	
	if collider.has_method("interact"):
		return collider
	
	var current = collider as Node
	while current != null and current != owner:
		if current.has_method("interact"):
			return current
		current = current.get_parent()
	
	return null
