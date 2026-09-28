class_name LoopData
extends Resource

@export var loop_number: int = 1
@export var loop_title: String = ""
@export_multiline var notification_text: String = ""

@export_group("Audio")
@export var ambient_stream: AudioStream
@export var ambient_volume_db: float = -6.0
@export var sound_cue: AudioStream

@export_group("Environment & Lighting")
@export var light_energy_multiplier: float = 1.0
@export var fog_density: float = 0.04
@export var fog_color: Color = Color(0.07, 0.07, 0.09, 1)

@export_group("Objects Control")
## Имена групп узлов, которые нужно сделать видимыми (visible = true, process_mode = INHERIT)
@export var show_groups: Array[String] = []
## Имена групп узлов, которые нужно скрыть (visible = false, process_mode = DISABLED)
@export var hide_groups: Array[String] = []

@export_group("Doors Control")
## Имена нод дверей, которые нужно принудительно открыть
@export var open_door_names: Array[String] = []
## Имена нод дверей, которые нужно принудительно закрыть
@export var close_door_names: Array[String] = []
## Имена нод дверей, которые нужно запереть
@export var lock_door_names: Array[String] = []

@export_group("Custom Scripted Event")
## Идентификатор скриптового события (например "event_silhouette", "event_radio_weeping")
@export var custom_event_id: String = ""
