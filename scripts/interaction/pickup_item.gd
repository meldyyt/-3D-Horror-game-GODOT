class_name PickupItem
extends StaticBody3D

signal picked_up(item: ItemData, player: Node)

@export var item_data: ItemData
@export var custom_prompt: String = ""
@export var pickup_sound: AudioStream = preload("res://assets/audio/pickup.wav")
@export var is_interactable: bool = true

@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

func get_interaction_prompt(_player: Node = null) -> String:
	if not custom_prompt.is_empty():
		return custom_prompt
	if item_data and not item_data.name.is_empty():
		return "Взять: " + item_data.name
	return "Взять предмет"

func can_interact(_player: Node = null) -> bool:
	return is_interactable and item_data != null

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	
	InventoryManager.add_item(item_data)
	picked_up.emit(item_data, player)
	
	if player and player.has_method("show_notification"):
		player.show_notification("Получено: " + item_data.name)
	
	if audio_player:
		if pickup_sound:
			audio_player.stream = pickup_sound
		if audio_player.stream:
			audio_player.reparent(get_parent())
			audio_player.play()
			audio_player.finished.connect(audio_player.queue_free)
	
	queue_free()

