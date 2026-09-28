class_name Interactable
extends CollisionObject3D

signal interacted(player: Node)

@export var prompt_message: String = "Взаимодействовать"
@export var is_interactable: bool = true

func get_interaction_prompt(_player: Node = null) -> String:
	return prompt_message

func can_interact(_player: Node = null) -> bool:
	return is_interactable

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	interacted.emit(player)
	_on_interact(player)

func _on_interact(_player: Node) -> void:
	pass
