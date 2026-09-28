class_name ItemData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var type: String = "item" # "key", "story", "puzzle", "item"
