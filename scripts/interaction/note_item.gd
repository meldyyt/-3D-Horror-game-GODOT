class_name NoteItem
extends StaticBody3D

@export var prompt_message: String = "Прочитать записку"
@export_multiline var note_text: String = "«Не пытайся спуститься. Этаж никогда не закончится...»"
@export var read_duration: float = 5.0
@export var is_interactable: bool = true

func get_interaction_prompt(_player: Node = null) -> String:
	return prompt_message

func can_interact(_player: Node = null) -> bool:
	return is_interactable

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	
	if player and player.has_method("show_notification"):
		player.show_notification(note_text, read_duration)
